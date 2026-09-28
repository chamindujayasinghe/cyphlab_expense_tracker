# Project Scope — CyphLab Expense Tracker

A simple, clean Expense Tracker mobile app built with Flutter and Firebase.
Focus is on implementation quality, not feature count — don't overcomplicate.

## Core Requirements (must have)

### Expense management
- [ ] Add a new expense
- [ ] Edit an existing expense
- [ ] Delete an expense
- [ ] Select a category for each expense

### Data
- [ ] Store expenses in Firebase (Cloud Firestore)

### Views
- [ ] Show total expenses for the selected/current month
- [ ] Show expense history/list
- [ ] Filter expenses by category
- [ ] Filter expenses by date

### Quality
- [ ] Proper form validation (required fields, valid positive amount, valid date)
- [ ] Handle loading states
- [ ] Handle empty states
- [ ] Handle error states

## Expense Data Model

| Field       | Type     | Required |
|-------------|----------|----------|
| id          | String   | yes (Firestore doc id) |
| title       | String   | yes |
| amount      | double   | yes (> 0) |
| category    | String / enum | yes |
| date        | DateTime | yes |
| note        | String   | no |

## Optional Features (nice to have)

- [ ] Simple expense chart
- [ ] Dark mode
- [ ] Monthly / category-wise summary
- [ ] Search
- [ ] Firebase Authentication
- [ ] Any other useful improvement

## Evaluation Criteria

- Flutter and Dart knowledge
- Firebase implementation
- Code structure and code quality
- UI quality and responsiveness
- Problem-solving approach
- App usability
- Attention to detail
- Effective use of modern development tools (incl. AI)

## Deliverables

- [ ] Complete project in a **public** GitHub repository
- [ ] README containing:
  - [ ] Project setup instructions
  - [ ] Features implemented
  - [ ] Technologies / packages used
  - [ ] AI tools used and how they helped
- [ ] Short screen recording of the finished app (Google Drive public link or unlisted YouTube)
- [ ] APK / release build link (if possible)
- [ ] Send both the GitHub link and the recording link

## Notes

- Must be able to understand, modify, debug, and explain all submitted code.
- Early, good-quality submissions get priority — aim to submit as soon as possible.
