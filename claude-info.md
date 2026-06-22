
# AI Prompt Operators Cheat Sheet

Коллекция полезных операторов для Claude, ChatGPT, Gemini, Grok и других LLM.

---

## 📌 `Act As`

> Назначает модели роль эксперта.

### Пример

```text
Act as a senior cybersecurity engineer.

Эффект

меняет стиль мышления модели;

добавляет профильную терминологию;

помогает получить более профессиональный ответ.


Использовать для

ИБ

DevOps

программирования

медицины

права



---

🎯 Goal

> Определяет конечную цель анализа.



Пример

Goal:
Find the root cause.

Эффект

Модель меньше отвлекается на второстепенные детали.


---

📖 Context

> Передаёт исходные данные.



Пример

Context:
500 users.
Linux infrastructure.
Budget is limited.

Эффект

Чем качественнее контекст, тем точнее ответ.


---

⚠️ Constraints

> Ограничивает возможные решения.



Пример

Constraints:
- Open source only
- No cloud services
- Budget under $1000

Эффект

Исключает неподходящие варианты.


---

🧠 Think Step By Step

> Пошаговое рассуждение.



Пример

Think step by step.

Эффект

лучше анализ;

меньше ошибок;

прозрачная логика.



---

🔍 Be Critical

> Включает режим критического анализа.



Пример

Be critical.

Эффект

Модель начинает искать недостатки и спорные места.


---

👿 Devil's Advocate

> Специально пытается опровергнуть собственный вывод.



Пример

Argue against your recommendation.

Эффект

Позволяет проверить идею на прочность.


---

🔴 Red Team Analysis

> Анализирует систему как атакующий.



Пример

Act as a hostile reviewer.

Эффект

Находит:

уязвимости;

ошибки конфигурации;

способы обхода защиты.



---

🔵 Blue Team Analysis

> Анализирует систему как защитник.



Пример

Act as a defender.

Эффект

Предлагает способы защиты от найденных угроз.


---

📊 Decision Matrix

> Создаёт матрицу принятия решений.



Пример

Create a decision matrix.

Эффект

Удобно для сравнения:

серверов;

VPN-протоколов;

языков программирования;

облачных платформ.



---

🔄 Self-Critique

> Самостоятельная проверка ответа.



Пример

Review your answer.
Find mistakes.
Correct them.

Эффект

Часто заметно повышает качество результата.


---

🚀 Универсальный шаблон

Act as a domain expert.

Goal:
<GOAL>

Context:
<CONTEXT>

Constraints:
<CONSTRAINTS>

Think step by step.

Identify:
- assumptions
- risks
- edge cases
- failure scenarios

Generate multiple approaches.

Compare them.

Analyze trade-offs.

Recommend the best option.

Review your answer.

Correct any mistakes.

Provide confidence levels.


---

⭐ Наиболее полезная комбинация

Think step by step.
Be critical.
Identify risks.
Identify edge cases.
Review your answer.
Correct any mistakes.
Provide confidence levels.

Для большинства задач этого достаточно, чтобы получить ответ существенно лучше стандартного запроса.
