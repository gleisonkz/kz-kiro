---
inclusion: auto
name: design-system
description: Use when creating, modifying, or discussing UI components, widgets, screens, or any visual element. Contains Design System rules, Atomic Design classification, and component lookup workflow for ds_monte_bravo_mobile.
---

# Design System — Monte Bravo

This steering file is loaded when working on UI components, widgets, or screens.

---

## Package

```yaml
ds_monte_bravo_mobile:
  git:
    url: git@github.com:MonteBravo/ds-monte-bravo-mobile.git
    ref: develop
```

Import: `package:ds_monte_bravo_mobile/`

---

## Golden Rule

**Never create a generic UI component inside a feature package.**

Generic components belong in the DS. Feature-specific components that will never be reused go in `presentation/widgets/` of that feature.

---

## Component Lookup Workflow

Every time a UI component is needed, follow this workflow without exception:

```
1. Identify the component needed
2. Search ds_monte_bravo_mobile for it
3. Found? → Use it. Never duplicate.
4. Not found? → Follow the "Component Not Found" protocol below.
```

---

## Component Not Found Protocol

When the component does not exist in `ds_monte_bravo_mobile`:

1. **Classify** the component using Atomic Design:

| Level | Definition | Examples |
|---|---|---|
| **Atom** | Smallest indivisible UI unit | `MbButton`, `MbLabel`, `MbIcon`, `MbDivider`, `MbBadge`, `MbAvatar` |
| **Molecule** | Combination of atoms with a specific function | `MbInputField`, `MbListTile`, `MbSearchBar`, `MbToggleItem` |
| **Organism** | Complex section combining molecules/atoms | `MbTransactionCard`, `MbNotificationItem`, `MbProfileHeader`, `MbBalanceCard` |

2. **Suggest** a name following the `Mb` prefix convention

3. **Always present the decision to the developer** before proceeding

4. **Wait for the developer's decision.** Do not create any component without explicit approval.

---

## Naming Convention

All DS components use the `Mb` prefix (Monte Bravo).

---

## Where Components Live

| Component type | Location |
|---|---|
| Generic, reusable across features | `ds_monte_bravo_mobile` |
| Feature-specific, won't be reused | `packages/features/<n>/lib/presentation/widgets/` |
| Temporarily local (pending DS contribution) | `presentation/widgets/` with `// TODO: move to DS` |

---

## What NOT to do

- Never recreate a DS component inside a feature
- Never hardcode design tokens — use DS color/spacing tokens
- Always use DS tokens and components
