# Community Learning Center Management System

**Name:** [Your Full Name]
**Section:** [Your Section]
**Course:** Mobile Development - Midterm Laboratory Examination

## Short Description

A Dart console application for a community learning center. Staff can add books and gadgets, sign up members (students or guests), lend and take back items, and view records. Late returns are charged a fee that depends on the type of item. Choices are made from numbered lists that can be searched, so IDs never have to be typed.

## Implemented Features

- Application title and a looping menu with 9 actions plus Exit.
- Pick-from-list input with search (type a number to select, a word to filter, `*` to show all, `0` to go back).
- Input validation: invalid menu choices, blank text, non-numeric or out-of-range numbers all show a message and ask again. The program never crashes.
- `try`/`on FormatException` for number input.
- Business rules: members have borrowing limits, items can run out, an item cannot be borrowed twice by the same member, late fees are computed on return.
- Optional sample records at startup so the lists can be tried right away.

## OOP Design

| Requirement | Where it is used |
|---|---|
| Abstract parent class | `CenterEntry` (general center record) and `Resource` |
| Subclasses with own implementation | `Book` and `Gadget` (loan days, late fee); `Student` and `Guest` (borrow limit, tier); `LogEntry` |
| Polymorphism | Lists of `Resource`, `Member` and `CenterEntry` call `tableCells`, `pickLabel` and `drawCard()` on each object |
| Mixins | `Stamped` (timestamps) and `CardPrinter` (printable record cards) |
| Encapsulation | Private fields (`_stock`, `_onShelf`, `_held`, `_fee`, ...) with getters and methods such as `takeOne()`, `putBack()`, `hold()`, `release()` |
| List and Map | `List<Resource>` shelf and `List<LogEntry>` log; `Map<String, Member>` roster looked up by ID |
| User-defined functions | `formatPeso(amount)`, `calculateLateFee(daysKept, allowedDays, feePerDay)`, plus helper methods such as `Input.pick`, `Input.number`, `Screen.wrap` |
| Operators | Arithmetic for late fees, comparison for limits and validation |

## Sample Test Scenarios

Choose **Yes** at the startup question to load the sample records (R001-R004 resources, M001-M003 members).

1. **Borrow and late return:** Option 3, pick Ana Cruz, pick Reading Tablet. A success message says it was borrowed free for 2 days. Option 4, pick Ana Cruz, Reading Tablet, then "Kept 5 days (3 day(s) late)". The program reports a late fee of P30.00, and option 9 shows P30.00 in late fees collected.
2. **Borrowing limit:** Option 3, pick Visitor Ben (a Guest, limit 1), borrow Math Made Easy. Open option 3 again: Visitor Ben is no longer in the member list because he reached his limit, and the Reading Tablet disappears from the list while no copy is on the shelf.
3. **Invalid input:**
   - At the main menu type `abc`: "Hmm, "abc" is not on the menu. Pick a number from 0 to 9."
   - In option 1, enter `abc` for copies: "Please type a whole number."
   - Enter `99` for copies: "Enter a number from 1 to 50."
   - Press Enter on an empty title: "Oops, this cannot be empty. Try again."
   - In any list, type a word that matches nothing: the list resets and shows everything again.

## How to Run

1. Install the [Dart SDK](https://dart.dev/get-dart) (version 3.0 or newer).
2. Open a terminal in this folder (the one containing `main.dart`).
3. Run:
   ```
   dart run main.dart
   ```
   Use a real terminal (for example the VS Code Terminal tab), not the Debug Console, because the program reads keyboard input.
