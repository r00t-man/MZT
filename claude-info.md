# AI Prompt Operators Cheat Sheet

Коллекция полезных операторов и техник промптинга для Claude, ChatGPT, Gemini, Grok и других LLM.

> Эти операторы не являются специальными командами модели. Это инструкции, которые помогают направить её поведение и получить более качественный результат.

---

# 📋 Содержание

- Act As
- Goal
- Context
- Constraints
- Output Format
- Think Step By Step
- Reason From First Principles
- Generate Multiple Approaches
- Compare Alternatives
- Trade-Off Analysis
- Decision Matrix
- Be Critical
- Devil's Advocate
- Challenge Your Conclusions
- Do Not Assume
- Identify Risks
- Identify Edge Cases
- Failure Scenarios
- Red Team Analysis
- Blue Team Analysis
- Self-Critique
- Review And Correct
- Confidence Level
- List Uncertainties
- Teach Me
- ELI5
- Socratic Method
- Multi-Persona Discussion
- Consensus Building
- Universal Prompt Template

---

# 🎭 Act As

> Назначает модели роль эксперта.

## Пример

```text
Act as a senior software architect.
```

```text
Act as a cybersecurity expert.
```

## Что делает

- меняет стиль анализа;
- использует профильные знания;
- помогает получать более профессиональные ответы.

## Когда использовать

- программирование;
- безопасность;
- DevOps;
- медицина;
- право;
- аналитика.

---

# 🎯 `Goal`

> Определяет конечную цель ответа.

## Пример

```text
Goal:
Find the root cause of the issue.
```

## Что делает

Помогает модели сосредоточиться на результате и не уходить в сторону.

---

# 📖 `Context`

> Передаёт исходные данные.

## Пример

```text
Context:
Company has 500 employees.
Migration must be completed in 30 days.
Budget is limited.
```

## Что делает

Добавляет важную информацию для принятия решений.

---

# ⚠️ `Constraints`

> Ограничивает допустимые варианты решений.

## Пример

```text
Constraints:
- Open source only
- Budget under $1000
- No cloud services
```

## Что делает

Исключает неподходящие решения ещё на этапе анализа.

---

# 📄 `Output Format`

> Указывает желаемый формат ответа.

## Пример

```text
Output format:
Markdown table
```

```text
Output format:
JSON
```

## Что делает

Позволяет получать ответы в удобном для дальнейшей обработки виде.

---

# 🧠 `Think Step By Step`

> Выполняет пошаговый анализ задачи.

## Пример

```text
Think step by step.
```

## Что делает

- разбивает задачу на этапы;
- улучшает логику ответа;
- снижает вероятность ошибок.

---

# 🏗️ `Reason From First Principles`

> Анализирует проблему с базовых принципов.

## Пример

```text
Reason from first principles.
```

## Что делает

Позволяет строить выводы с нуля, а не опираться на шаблонные решения.

---

# 🔀 `Generate Multiple Approaches`

> Создаёт несколько вариантов решения.

## Пример

```text
Generate 3 different approaches.
```

## Что делает

Показывает альтернативные способы достижения цели.

---

# ⚖️ `Compare Alternatives`

> Сравнивает предложенные варианты.

## Пример

```text
Compare all approaches.
```

## Что делает

Позволяет увидеть преимущества и недостатки каждого решения.

---

# 🔄 `Trade-Off Analysis`

> Анализирует компромиссы между решениями.

## Пример

```text
Analyze trade-offs.
```

## Что делает

Показывает последствия выбора.

### Примеры

- безопасность vs производительность;
- стоимость vs надёжность;
- простота vs гибкость.

---

# 📊 `Decision Matrix`

> Создаёт матрицу принятия решений.

## Пример

```text
Create a decision matrix.
```

## Что делает

Сравнивает варианты по заданным критериям.

---

# 🔍 `Be Critical`

> Включает режим критического анализа.

## Пример

```text
Be critical.
```

## Что делает

Заставляет модель искать недостатки вместо подтверждения идеи пользователя.

---

# 👿 `Devil's Advocate`

> Выступает против собственных выводов.

## Пример

```text
Argue against your recommendation.
```

## Что делает

Помогает выявить слабые места решения.

---

# 🥊 `Challenge Your Conclusions`

> Проверяет собственные выводы.

## Пример

```text
Challenge your conclusions.
```

## Что делает

Пытается найти логические ошибки и спорные места.

---

# 🚫 `Do Not Assume`

> Запрещает делать предположения без данных.

## Пример

```text
Do not assume missing information.
```

## Что делает

Снижает количество галлюцинаций модели.

---

# ⚠️ `Identify Risks`

> Поиск рисков.

## Пример

```text
Identify risks.
```

## Что делает

Находит потенциальные угрозы и проблемы.

---

# 🧩 `Identify Edge Cases`

> Поиск нестандартных сценариев.

## Пример

```text
Identify edge cases.
```

## Что делает

Рассматривает редкие ситуации, которые часто забывают учитывать.

---

# 💥 `Failure Scenarios`

> Анализ возможных отказов.

## Пример

```text
List failure scenarios.
```

## Что делает

Показывает, как и почему решение может сломаться.

---

# 🔴 `Red Team Analysis`

> Анализирует систему как атакующий.

## Пример

```text
Act as a hostile reviewer.
```

## Что делает

Ищет:

- уязвимости;
- способы обхода защиты;
- ошибки конфигурации;
- точки отказа.

---

# 🔵 `Blue Team Analysis`

> Анализирует систему как защитник.

## Пример

```text
Act as a defender.
```

## Что делает

Предлагает меры защиты от найденных угроз.

---

# 🔄 `Self-Critique`

> Самостоятельно проверяет ответ.

## Пример

```text
Review your answer.
Find mistakes.
```

## Что делает

Помогает находить собственные ошибки до выдачи результата.

---

# ✅ `Review And Correct`

> Выполняет дополнительную проверку и исправление.

## Пример

```text
Review and correct any mistakes.
```

## Что делает

Улучшает качество итогового ответа.

---

# 📈 `Confidence Level`

> Указывает уровень уверенности.

## Пример

```text
Provide confidence levels.
```

## Что делает

Позволяет понять, насколько надёжен каждый вывод.

---

# ❓ `List Uncertainties`

> Перечисляет неизвестные факторы.

## Пример

```text
List uncertainties.
```

## Что делает

Показывает, каких данных не хватает для точного ответа.

---

# 🎓 `Teach Me`

> Обучающий режим.

## Пример

```text
Teach me progressively.
```

## Что делает

Объясняет тему от простого к сложному.

---

# 👶 `ELI5`

> Объяснение для новичка.

## Пример

```text
Explain like I'm 5.
```

## Что делает

Максимально упрощает сложные концепции.

---

# ❔ `Socratic Method`

> Использует сократический метод обучения.

## Пример

```text
Use the Socratic method.
```

## Что делает

Задаёт вопросы вместо готовых ответов.

---

# 👥 `Multi-Persona Discussion`

> Создаёт дискуссию между экспертами.

## Пример

```text
Simulate discussion between:
- Engineer
- Economist
- Security Expert
```

## Что делает

Позволяет посмотреть на проблему с разных сторон.

---

# 🤝 `Consensus Building`

> Формирует общий вывод после обсуждения.

## Пример

```text
Provide a consensus recommendation.
```

## Что делает

Объединяет различные точки зрения в одно решение.

---

# 🚀 Универсальный шаблон

```text
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
```

---

# ⭐ Самая полезная комбинация

Для большинства задач достаточно:

```text
Think step by step.

Be critical.

Identify risks.

Identify edge cases.

Review your answer.

Correct any mistakes.

Provide confidence levels.
```

Эта комбинация обычно даёт значительно более качественные ответы независимо от используемой LLM.