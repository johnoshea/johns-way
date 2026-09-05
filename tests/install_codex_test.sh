#!/usr/bin/env bash
root=${root:?set by tests/run.sh}

test_public_codex_catalog_resolves_the_shared_plugin() {
    local source manifest
    source=$(jq -er '.plugins[] | select(.name == "johns-way") | .source.path' "$root/.agents/plugins/marketplace.json")
    manifest="$root/$source/.codex-plugin/plugin.json"
    jq -e '.name == "johns-way" and (.version | type == "string") and .skills == "./skills/"' "$manifest" >/dev/null || return 1
    [ -f "$root/$source/skills/routing/SKILL.md" ] || return 1
    [ -f "$root/$source/hooks/hooks.json" ] || return 1
    assert_eq "$(jq -r .version "$root/.claude-plugin/plugin.json")" "$(jq -r .version "$manifest")"
}

test_codex_install_refreshes_edits_and_removes_deleted_files() {
    mkdir -p 'checkout with spaces/bin' 'checkout with spaces/.codex-plugin' 'checkout with spaces/skills/example' fake-bin
    cp "$root/bin/johns-way-install-codex" 'checkout with spaces/bin/'
    cp "$root/.codex-plugin/plugin.json" 'checkout with spaces/.codex-plugin/'
    echo old > 'checkout with spaces/skills/example/SKILL.md'
    echo obsolete > 'checkout with spaces/skills/example/deleted.md'
    cat > fake-bin/codex <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$INSTALL_LOG"
EOF
    chmod +x fake-bin/codex
    export INSTALL_LOG="$PWD/install.log"
    export PATH="$PWD/fake-bin:$PATH"
    bash 'checkout with spaces/bin/johns-way-install-codex'
    local plugin='checkout with spaces/.local/codex/plugins/johns-way'
    local first_version
    first_version=$(jq -r .version "$plugin/.codex-plugin/plugin.json")
    assert_eq old "$(cat "$plugin/skills/example/SKILL.md")" || return 1
    echo new > 'checkout with spaces/skills/example/SKILL.md'
    rm 'checkout with spaces/skills/example/deleted.md'
    bash 'checkout with spaces/bin/johns-way-install-codex'
    assert_eq new "$(cat "$plugin/skills/example/SKILL.md")" || return 1
    [ ! -e "$plugin/skills/example/deleted.md" ] || return 1
    [ ! -e "$plugin/.local" ] || return 1
    [ "$first_version" != "$(jq -r .version "$plugin/.codex-plugin/plugin.json")" ] || return 1
    assert_eq "$(cat "$root/.codex-plugin/plugin.json")" "$(cat 'checkout with spaces/.codex-plugin/plugin.json')" || return 1
    assert_contains "$(cat install.log)" 'plugin add johns-way@johns-way-local'
}

test_codex_install_stops_when_marketplace_registration_fails() {
    mkdir -p checkout/bin checkout/.codex-plugin fake-bin
    cp "$root/bin/johns-way-install-codex" checkout/bin/
    cp "$root/.codex-plugin/plugin.json" checkout/.codex-plugin/
    printf '#!/usr/bin/env bash\nexit 19\n' > fake-bin/codex
    chmod +x fake-bin/codex
    local status=0
    PATH="$PWD/fake-bin:$PATH" bash checkout/bin/johns-way-install-codex || status=$?
    assert_eq 19 "$status"
}
