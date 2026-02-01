test-websocket:
    script/test_websocket

test-interactive:
    script/test_interactive

test-attach:
    script/test_attach

kill-all:
    script/kill_all_sprites

attach:
    script/attach

release *args:
    script/release {{ args }}
