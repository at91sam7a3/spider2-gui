@echo off
REM Non-interactive login for Conan 1.x remote "miraspec" (used by pull_deps / build scripts).
set CONAN_REVISIONS_ENABLED=1
conan user ovyn -p Qwerty123 -r miraspec
