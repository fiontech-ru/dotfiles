# setup-my-prompt.sh

Скрипт, который настраивает информативное приглашение Bash с индикатором
Docker-контейнера, текущей git-веткой и её состоянием (modified / staged /
untracked / stash / ahead / behind). Работает на Ubuntu, Debian, CentOS,
Fedora, Arch Linux и в Docker-контейнерах на их основе.

## Зачем это нужно программисту

Приглашение вида:

```
user@host:~/project 📦 (feature/login*+%$) $
```

Сразу даёт ответы на вопросы, не выполняя ни одной команды:

| Элемент | Что сообщает |
|---------|--------------|
| `~/project` (фиолетовым) | Где вы находитесь — быстрее ориентироваться в дереве каталогов. |
| `📦` / `🏠` | Вы внутри Docker-контейнера или на хосте. Критично при работе с контейнерами: не перепутать, где выполняешь команду. |
| `(feature/login...)` (зелёным) | Текущая git-ветка. |
| `*` | Есть **modified** отслеживаемые файлы (не закоммичены). |
| `+` | Есть **staged** файлы (в индексе, готовы к коммиту). |
| `%` | Есть **untracked** файлы (git их ещё не знает). |
| `$` | В репозитории есть **stash** (отложенные изменения). |
| `<` | Ветка **отстаёт** от upstream (нужно `git pull`). |
| `>` | Ветка **опережает** upstream (нужно `git push`). |
| `<>` | Ветка **разошлась** с upstream (нужен rebase/merge). |

Всё это — без `git status`, без `git log`. Просто посмотрел на приглашение —
и знаешь, что делать дальше.

## Что делает скрипт

1. **Определяет дистрибутив** через `/etc/os-release` и сообщает его.
2. **Ищет источник функции `__git_ps1`** в стандартных путях:
   - `git-prompt.sh` — Arch, Fedora, иногда Debian;
   - `bash-completion` — Ubuntu, Debian, CentOS.
3. **Если ни одного источника нет** — выводит точную команду установки для
   вашего дистрибутива и **завершается, ничего не меняя**.
4. **Проверяет**, не настроен ли уже `.bashrc` (по маркеру
   `# >>> my prompt >>>`). Если настроен — выходит, не дублируя.
5. **Создаёт** `~/.bashrc`, если файла нет.
6. **Делает бэкап** `~/.bashrc.bak.<дата-время>`.
7. **Добавляет** в конец `.bashrc` блок, который:
   - подключает найденный источник `__git_ps1`;
   - включает четыре флага `GIT_PS1_*` (dirty, stash, untracked, upstream);
   - задаёт `PS1` с эмодзи Docker и git-веткой.
8. **Применяет изменения** в текущей сессии — если скрипт запущен через
   `source`. Если запущен как обычный исполняемый файл — подсказывает
   выполнить `source ~/.bashrc`.

## Использование

### Рекомендуемый способ (с автоматическим применением)

```bash
chmod +x setup-my-prompt.sh
source setup-my-prompt.sh
```

При таком запуске скрипт **сам** обновит приглашение в текущем терминале —
открывать новый не нужно.

### Альтернативный способ (без `source`)

```bash
chmod +x setup-my-prompt.sh
./setup-my-prompt.sh
```

Скрипт настроит `.bashrc`, но **не сможет** изменить приглашение в текущем
терминале (ограничение Unix: дочерний процесс не меняет окружение родителя).
В конце он подскажет выполнить:

```bash
source ~/.bashrc
```

## Пример вывода

### Первый запуск (всё в порядке)

```
🐧 Обнаружена система: ubuntu
✅ Найден bash-completion: /usr/share/bash-completion/bash_completion (__git_ps1 будет доступна)
💾 Бэкап: /home/user/.bashrc.bak.20260101-120000
✅ Настройка добавлена в /home/user/.bashrc
🔄 Обновляю текущий терминал...
🎉 Готово! Приглашение обновлено в текущей сессии.
```

### Повторный запуск

```
🐧 Обнаружена система: ubuntu
✅ Найден bash-completion: /usr/share/bash-completion/bash_completion (__git_ps1 будет доступна)
✅ Настройка уже присутствует в /home/user/.bashrc — изменений не требуется.
```

### Не хватает зависимостей

```
🐧 Обнаружена система: arch
❌ Не найдено ни git-prompt.sh, ни bash-completion.
   Без них git-ветка в приглашении работать не будет.

   Установите пакет bash-completion:
     sudo pacman -S bash-completion

   Либо установите git (он содержит git-prompt.sh на Arch/Fedora):
     sudo pacman -S git

⛔ Настройка отменена. Установите зависимости и запустите скрипт снова.
```

## Требования

- Bash 4+ (стандарт в большинстве дистрибутивов Linux).
- Один из источников `__git_ps1`:
  - пакет `git` (содержит `git-prompt.sh` на Arch и Fedora);
  - пакет `bash-completion` (содержит `__git_ps1` для Ubuntu, Debian, CentOS).
- Шрифт с поддержкой эмодзи (📦, 🏠). В большинстве современных
  терминалов работает из коробки.

## Что будет на разных системах

| Система | Источник `__git_ps1` | Результат |
|---------|----------------------|-----------|
| **Ubuntu/Debian** | `bash-completion` (обычно уже установлен) | ✅ Работает сразу |
| **CentOS/RHEL** | `bash-completion` (если установлен; иначе подсказка) | ✅ Или подсказка с `yum install epel-release && yum install bash-completion` |
| **Fedora** | `git-prompt.sh` (есть в пакете git) | ✅ Работает |
| **Arch/Manjaro** | `git-prompt.sh` (есть в пакете git) | ✅ Работает |
| **Docker (Ubuntu-based)** | `bash-completion` может отсутствовать → подсказка | ✅ Или подсказка |

## Расшифровка индикаторов git

После установки скрипта в скобках с веткой вы увидите комбинацию символов:

| Символ | Значение | Что делать |
|--------|----------|------------|
| `*` | Modified (отслеживаемые файлы изменены) | `git diff` → `git add` → `git commit` |
| `+` | Staged (изменения в индексе) | `git commit` |
| `%` | Untracked (новые файлы) | `git add <file>` |
| `$` | Есть stash | `git stash list` / `git stash pop` |
| `<` | Отстаём от upstream | `git pull` |
| `>` | Опережаем upstream | `git push` |
| `<>` | Разошлись с upstream | `git pull --rebase` или merge |

Примеры приглашений:

```
~/project 🏠 (main) $              # чисто, всё синхронизировано
~/project 🏠 (main*) $             # есть modified
~/project 🏠 (main+) $             # есть staged
~/project 🏠 (main*+%) $           # и modified, и staged, и untracked
~/project 🏠 (feature*<) $         # modified + отстаём от upstream
~/project 📦 (main$) $             # в Docker, есть stash
```

## Откат изменений

Всё, что добавляет скрипт, обёрнуто в маркеры:

```
# >>> my prompt >>>
...
# <<< my prompt <<<
```

### Удалить блок вручную

Найдите в `~/.bashrc` эти маркеры и удалите всё между ними, затем:

```bash
source ~/.bashrc
```

### Восстановить из бэкапа

```bash
ls ~/.bashrc.bak.*              # найти последний бэкап
cp ~/.bashrc.bak.20260101-120000 ~/.bashrc
source ~/.bashrc
```

### Временно вернуть стандартное приглашение (без правки файла)

```bash
PS1='\u@\h:\w\$ '
```

После перезапуска терминала вернётся кастомное (из `.bashrc`).

## Как это работает внутри

Блок, который добавляется в `.bashrc`:

```bash
# >>> my prompt >>>
# Подключаем __git_ps1 из доступного источника
[ -f /usr/share/git/completion/git-prompt.sh ] && source /usr/share/git/completion/git-prompt.sh
[ -f /usr/share/git-core/contrib/completion/git-prompt.sh ] && source /usr/share/git-core/contrib/completion/git-prompt.sh
[ -f /etc/bash_completion.d/git-prompt.sh ] && source /etc/bash_completion.d/git-prompt.sh
[ -f /usr/share/bash-completion/bash_completion ] && source /usr/share/bash-completion/bash_completion

# Флаги __git_ps1 — что показывать в скобках (ветка)
# *  modified tracked   +  staged   %  untracked   $  stash
# <  behind upstream    >  ahead     <> diverged
export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWSTASHSTATE=1
export GIT_PS1_SHOWUNTRACKEDFILES=1
export GIT_PS1_SHOWUPSTREAM="auto"

export PS1='\u@\h:\[\e[38;5;133m\]\w\[\e[m\] $( [ -f /.dockerenv ] && echo "📦" || echo "🏠" )\[\033[32m\]$(__git_ps1)\[\033[00m\]\$ '
# <<< my prompt <<<
```

- `[ -f ... ] && source ...` — подключает только существующие файлы,
  без ошибок и без `2>/dev/null`.
- `GIT_PS1_SHOWDIRTYSTATE=1` — включает `*` (modified) и `+` (staged).
- `GIT_PS1_SHOWSTASHSTATE=1` — включает `$` при наличии stash.
- `GIT_PS1_SHOWUNTRACKEDFILES=1` — включает `%` при untracked-файлах.
- `GIT_PS1_SHOWUPSTREAM="auto"` — включает `<`/`>`/`<>` для отставания,
  опережения и расхождения с upstream.
- `\[ \]` — говорят Bash, что escape-последовательности не занимают места
  на экране (иначе ломается перенос строк).
- `$(...)` — команда вычисляется при каждом показе приглашения, поэтому
  индикатор Docker и git-статус всегда актуальны.
- `/.dockerenv` — файл, который Docker создаёт в корне контейнера;
  надёжный признак «мы внутри контейнера».

## Безопасность

- Скрипт **не требует sudo** и меняет только `~/.bashrc` текущего пользователя.
- Перед изменением всегда создаётся бэкап.
- Изменения ограничены маркерами — легко найти и удалить.
- Скрипт идемпотентен: безопасно запускать повторно.
- При запуске через `source` не закрывает терминал даже при ошибке.

## Ограничение Unix, о котором стоит знать

Дочерний процесс **не может** изменить переменные окружения родительского
shell. Поэтому скрипт, запущенный как `./setup-my-prompt.sh`, не может
обновить `PS1` в вашем терминале — он может только изменить `~/.bashrc`.
Чтобы применить изменения немедленно, запускайте через
`source setup-my-prompt.sh` или выполняйте `source ~/.bashrc` вручную.
