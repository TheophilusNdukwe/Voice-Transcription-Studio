# Voice Transcription Demo

A real-time voice transcription application built with Elm, leveraging the Web Speech API.

## Features

- Real-time voice transcription
- Word frequency and filler word detection
- Interactive user interface with status indicators
- Modern and responsive design inspired by DeepGram's aesthetic
- Error handling and continuous transcription capabilities

## Project Structure

- `elm.json`: Project configuration and dependencies for Elm 0.19.1.
- `src/Main.elm`: The main Elm application logic, including model and view definitions.
- `index.html`: The HTML entry point with styling and embedded Elm and JavaScript.
- `app.js`: JavaScript integration with the Web Speech API.

## Dependencies

The application relies on the following Elm packages:

- `elm/browser`: ^1.0.2
- `elm/core`: ^1.0.5
- `elm/html`: ^1.0.0
- `elm/json`: ^1.1.3
- `elm/time`: ^1.0.0

## Setup Instructions

### Prerequisites

- Elm 0.19.1 or later
- A modern web browser with Web Speech API support

### Installation

1. Clone the repository:
    ```bash
    git clone <repository-url>
    ```

2. Navigate to the project directory:
    ```bash
    cd voice-elm-demo
    ```

3. Install Elm dependencies:
    ```bash
    elm make src/Main.elm --output=elm.js
    ```

4. Open `index.html` in your browser to run the application.

## Usage

- Click "Start Recording" to begin transcription.
- View live transcriptions and statistics like word count and filler word percentage.
- Click "Stop Recording" to pause transcription.
- Click "Clear" to reset the transcription area.

## Known Issues

- The application requires browser support for the Web Speech API. Use Chrome or Edge for the best experience.
- Speech recognition may not work well for non-English languages as it is currently set to 'en-US'.

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Acknowledgments

- Inspired by DeepGram's aesthetic and capabilities.
- Special thanks to all libraries and resources that make open-source software so great.
