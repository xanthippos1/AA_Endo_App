# Voice Timer App Implementation Plan

## General Guideline

- [ ] Medication names should be in MAGENTA and BOLD
- [ ] Titles like 'Medical History' should be in Light Blue

## Phase 1: Project Structure and Theme Setup

### 1. Set up project structure
- [x] Create `lib/features/patient/` for sea-specific code
- [x] Create `lib/shared/widgets/` for reusable UI components
- [x] Create `lib/core/theme/` for theme configuration

### 2. Configure dark theme
- [ ] Create `app_theme.dart` with MaterialApp dark theme
- [ ] Define color scheme, text styles, and button themes
- [ ] Apply theme to MaterialApp

## Phase 2: Basic Search tab page (Testable at Each Step)

- [x] Create four tabs at the bottom titled: Search (the default greeting one), Patient, New, Date
- [x] On the default Search tab page, add 4 search boxes with small titles: Name, AMKA, Birth, Visit and a `Search` button
- [x] Right now we will only implement the AMKA search. Allow the user to type in a 4 digit number
- [x] Once the number is entered and the `Search` button is pressed, search the patient data in `.\data` directory. Each patient has a .json file. There is an `identity` field and in that field an `amka` number with only the last 4 digits showing. List the patient that matches that number and allow that patient listed to be selectable.
- [x] Selecting the patient from the list should result in the `Patient` tab being selected and a new fresh page in this tab with the `identity` information of this patient followed by a list of visits by inverse chronological order

## Pase 3: Detailed Patient Visit (Testable at Each Step)

- [x] At the `Patient` page where the list of Visits is, once a visit is selected, display the details of the visit, again in a list if there are more than one results. results can be labs (imaging, cbc, etc), instructions, medications, notes. The labs usually have a date associated with them. Again, display them in reverse chronological order. If instructions or medications exist, display those first on the list, followed by labs, with the notes at the end. List the lab date and type: `lab (13/11/2019) ECHO ΑΝΩ-ΚΑΤΩ ΚΟΙΛΙΑΣ`. For medications and instructions, just those words.
- [x] When in the Visits list or after a Visit has been selected from the list, instead of displaying the AMKA, DOB, Address and Phone at the top, display the following:
  - Social | Presenting Illness | Referal
  - Medical History
- [x] To the list of visits, notes, labs prepend the following (as selectable list items): family history, gynecological_history

## Phase 4: Visit details

- [x] When in the Visit list, let's make the visits selectable and display the detail of either the instructions, lab result or any other item. If the item is a lab result it should be nicely tabuled with the title of the table and date and columns for the item, measurement and nomincal values in three columns. Make sure it is scrolable if is doesn't fit. For tables use alternating muted (still dark theme with whote letters) colors to make it easier to read.
- [ ] Add an expand all button next to the Visit - date on ethe same line, and when pressed make all the items (instructions, labs etc.) all expand as one bug scrollable.

## Phase 5: Original Images

- [x] At the top of the page to the right of the name on the mane page and to the right of the <-- Back button when in Visit detail, dsiplay 1-N selectable small buttons with the number 1 through N inside the button border. These buttons will correspond to jpeg images associated with each patient. The images are located in `./jpeg/images` directory and the format is `PatientXXX_N.jpg` where N is a number from 1 to N corresponding to each of the N jpeg files associalted with this patient (`patient_id` field in the data file). If there is 1 jpeg for this patient, there should be 1 button with the number 1 inside it. If there are 3, there should be 3 buttons 1, 2, 3.
- [x] When a button is pressed display the corresponding jpeg image full screen (ie fit both width and height of the image to the screen).

## Phase 9: Polish and Error Handling

### 10. Handle permission denial
- [ ] Show appropriate UI when permissions denied
- [ ] Disable voice features gracefully
- [ ] Maintain manual-only mode functionality

### 11. Testing and refinement
- [ ] Test voice command recognition accuracy
- [ ] Add proper logging with dart:developer
- [ ] Polish UI animations and transitions

## Key Implementation Notes
- Time format: SS.S (seconds with one decimal)
- TimerDisplay uses Ticker for smooth refresh
- Stopwatch lives in TimerPage, passed to TimerDisplay
- Each phase produces a testable app
- No ChangeNotifier needed for simple timer logic