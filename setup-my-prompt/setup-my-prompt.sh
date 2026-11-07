#!/usr/bin/env bash
#
# setup-my-prompt.sh
# Настраивает PS1 с эмодзи Docker и git-веткой + полезные флаги __git_ps1.
# Проверяет зависимости и подсказывает, чего не хватает.
# Ничего не устанавливает сам — только сообщает.
#
# Запуск:
#   source setup-my-prompt.sh    (рекомендуется — применит PS1 сразу)
#   ./setup-my-prompt.sh         (настроит .bashrc, попросит source вручную)
#
set -euo pipefail

BASHRC="${HOME}/.bashrc"
MARKER="# >>> my prompt >>>"
MARKER_END="# <<< my prompt <<<"

# ---------------------------------------------------------------------------
# 0. Определяем, запущен ли скрипт через source
# ---------------------------------------------------------------------------
if [ "${BASH_SOURCE[0]:-}" = "${0:-}" ]; then
    SOURCED=0
else
    SOURCED=1
fi

# ---------------------------------------------------------------------------
# 1. Определяем дистрибутив
# ---------------------------------------------------------------------------
detect_distro() {
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        echo "${ID:-unknown}"
    else
        echo "unknown"
    fi
}

DISTRO=$(detect_distro)
echo "🐧 Обнаружена система: ${DISTRO}"

# ---------------------------------------------------------------------------
# 2. Проверяем наличие __git_ps1
# ---------------------------------------------------------------------------
GIT_PROMPT=""
BASH_COMPLETION=""

for p in \
    /usr/share/git/completion/git-prompt.sh \
    /usr/share/git-core/contrib/completion/git-prompt.sh \
    /etc/bash_completion.d/git-prompt.sh
do
    if [ -f "$p" ]; then
        GIT_PROMPT="$p"
        break
    fi
done

for p in \
    /usr/share/bash-completion/bash_completion \
    /etc/bash_completion
do
    if [ -f "$p" ]; then
        BASH_COMPLETION="$p"
        break
    fi
done

if [ -z "$GIT_PROMPT" ] && [ -z "$BASH_COMPLETION" ]; then
    echo ""
    echo "❌ Не найдено ни git-prompt.sh, ни bash-completion."
    echo "   Без них git-ветка в приглашении работать не будет."
    echo ""
    echo "   Установите пакет bash-completion:"
    case "$DISTRO" in
        ubuntu|debian)
            echo "     sudo apt update && sudo apt install bash-completion"
            ;;
        centos|rhel|rocky|almalinux)
            echo "     sudo yum install epel-release"
            echo "     sudo yum install bash-completion"
            ;;
        fedora)
            echo "     sudo dnf install bash-completion"
            ;;
        arch|manjaro)
            echo "     sudo pacman -S bash-completion"
            ;;
        *)
            echo "     Используйте пакетный менеджер вашей системы для установки bash-completion."
            ;;
    esac
    echo ""
    echo "   Либо установите git (он содержит git-prompt.sh на Arch/Fedora):"
    case "$DISTRO" in
        ubuntu|debian) echo "     sudo apt install git" ;;
        centos|rhel)   echo "     sudo yum install git" ;;
        fedora)        echo "     sudo dnf install git" ;;
        arch|manjaro)  echo "     sudo pacman -S git" ;;
    esac
    echo ""
    echo "⛔ Настройка отменена. Установите зависимости и запустите скрипт снова."
    return 1 2>/dev/null || exit 1
fi

if [ -n "$GIT_PROMPT" ]; then
    echo "✅ Найден git-prompt.sh: $GIT_PROMPT"
elif [ -n "$BASH_COMPLETION" ]; then
    echo "✅ Найден bash-completion: $BASH_COMPLETION (__git_ps1 будет доступна)"
fi

# ---------------------------------------------------------------------------
# 3. Проверяем, не настроено ли уже
# ---------------------------------------------------------------------------
if grep -qF "$MARKER" "$BASHRC" 2>/dev/null; then
    echo "✅ Настройка уже присутствует в $BASHRC — изменений не требуется."
    if [ "$SOURCED" = "1" ]; then
        # shellcheck disable=SC1090
        source "$BASHRC"
        echo "🔄 Приглашение применено в текущей сессии."
    fi
    return 0 2>/dev/null || exit 0
fi

# ---------------------------------------------------------------------------
# 4. Создаём .bashrc, если нет
# ---------------------------------------------------------------------------
if [ ! -f "$BASHRC" ]; then
    echo "ℹ️  $BASHRC не найден — создаю."
    touch "$BASHRC"
fi

# ---------------------------------------------------------------------------
# 5. Бэкап и добавление блока
# ---------------------------------------------------------------------------
BACKUP="${BASHRC}.bak.$(date +%Y%m%d-%H%M%S)"
cp "$BASHRC" "$BACKUP"
echo "💾 Бэкап: $BACKUP"

{
    echo ""
    echo "$MARKER"
    echo "# Подключаем __git_ps1 из доступного источника"
    for p in \
        /usr/share/git/completion/git-prompt.sh \
        /usr/share/git-core/contrib/completion/git-prompt.sh \
        /etc/bash_completion.d/git-prompt.sh
    do
        echo "[ -f $p ] && source $p"
    done
    echo "[ -f /usr/share/bash-completion/bash_completion ] && source /usr/share/bash-completion/bash_completion"
    echo ""
    echo "# Флаги __git_ps1 — что показывать в скобках (ветка)"
    echo "# *  modified tracked   +  staged   %  untracked   \$  stash"
    echo "# <  behind upstream    >  ahead     <> diverged"
    echo "export GIT_PS1_SHOWDIRTYSTATE=1"
    echo "export GIT_PS1_SHOWSTASHSTATE=1"
    echo "export GIT_PS1_SHOWUNTRACKEDFILES=1"
    echo "export GIT_PS1_SHOWUPSTREAM=\"auto\""
    echo ""
    echo "export PS1='\\u@\\h:\\[\\e[38;5;133m\\]\\w\\[\\e[m\\] \$( [ -f /.dockerenv ] && echo \"📦\" || echo \"🏠\" )\\[\\033[32m\\]\$(__git_ps1)\\[\\033[00m\\]\\\$ '"
    echo "$MARKER_END"
} >> "$BASHRC"

echo "✅ Настройка добавлена в $BASHRC"

# ---------------------------------------------------------------------------
# 6. Применяем изменения
# ---------------------------------------------------------------------------
if [ "$SOURCED" = "1" ]; then
    echo "🔄 Обновляю текущий терминал..."
    # shellcheck disable=SC1090
    source "$BASHRC"
    echo "🎉 Готово! Приглашение обновлено в текущей сессии."
else
    echo ""
    echo "ℹ️  Скрипт запущен как отдельный процесс и не может изменить"
    echo "   приглашение в текущем терминале (ограничение Unix)."
    echo ""
    echo "Чтобы применить изменения сейчас, выполните:"
    echo ""
    echo "    source ~/.bashrc"
    echo ""
    echo "Или просто откройте новый терминал."
fi
