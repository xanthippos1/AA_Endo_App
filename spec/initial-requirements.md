
- I want to build an app that an andocronologist can use to enter patient, clinical exam, lab results. The app should also allow the doctor to access/search information entered from previous visits. The search capabilities should extend beyond searching by name to medical_id, birth data, visit date etc.

The app should be built with Flutter and have the following features:

## Basic UI

Simple initial greeting page with:

- The ability to search by patient last name, last 4 digits of AMKA number, birth date, or patient visit date. The search result should be displayed as a list of patients that meet the seatch criteria.
- Four tabs at the bottom: Search (default), Patient, New, Date.
- A settings gear in the top right: the only setting allowed for now is dark vs light theme

A more detailed `Patient` greeting page : once a patient is selected from the list displayed as result of the search.

- The Patient page should have the basic demographic information of the page in the top half followed by a list of visits, listed in inverse chronological order.

A more detailed `Exam` page once a spcific visit is selected from the list of available visits in the `Patient` page

## Other requirements

### Theming

- The app uses dark or light mode (default is dark)
- Theming should be done by setting the `theme` in the `MaterialApp`, rather than hardcoding colors and sizes in the widgets themselves

### Compatibilty

- The app should work on iPad, iPhone, Android phone, macOS and Windows

### Code Style

- Ensure proper separation of concerns by creating a suitable folder structure
- Prefer small composable widgets over large ones
- Prefer using flex values over hardcoded sizes when creating widgets inside rows/columns, ensuring the UI adapts to various screen sizes
- Use `log` from `dart:developer` rather than `print` or `debugPrint` for logging