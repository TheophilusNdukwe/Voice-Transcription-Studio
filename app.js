// app.js - Web Speech API integration with Elm
let recognition;
let isRecording = false;

// Initialize after Elm loads
function initializeSpeechRecognition(app) {
    // Check for browser support
    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
    
    if (!SpeechRecognition) {
        app.ports.recordingError.send("Speech recognition not supported in this browser");
        return;
    }
    
    recognition = new SpeechRecognition();
    recognition.continuous = true;
    recognition.interimResults = true;
    recognition.lang = 'en-US';
    
    // Handle results
    recognition.onresult = (event) => {
        for (let i = event.resultIndex; i < event.results.length; i++) {
            if (event.results[i].isFinal) {
                const transcript = event.results[i][0].transcript.trim();
                if (transcript) {
                    console.log('Sending transcript to Elm:', transcript);
                    app.ports.transcriptionReceived.send(transcript);
                }
            }
        }
    };
    
    // Handle errors
    recognition.onerror = (event) => {
        console.error('Speech recognition error:', event.error);
        app.ports.recordingError.send(`Recognition error: ${event.error}`);
        isRecording = false;
    };
    
    // Handle end
    recognition.onend = () => {
        console.log('Speech recognition ended');
        // Restart if still recording
        if (isRecording) {
            try {
                recognition.start();
            } catch (e) {
                console.error('Failed to restart recognition:', e);
                app.ports.recordingError.send('Failed to restart recognition');
                isRecording = false;
            }
        }
    };
    
    // Handle start
    recognition.onstart = () => {
        console.log('Speech recognition started');
    };
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    console.log('Initializing Elm app...');
    
    const app = Elm.Main.init({
        node: document.getElementById('elm-app')
    });
    
    console.log('Elm app initialized, setting up speech recognition...');
    initializeSpeechRecognition(app);
    
    // Subscribe to Elm ports
    app.ports.startRecording.subscribe(() => {
        console.log('Start recording requested');
        isRecording = true;
        try {
            if (recognition) {
                recognition.start();
            } else {
                app.ports.recordingError.send('Speech recognition not initialized');
            }
        } catch (e) {
            console.error('Failed to start recording:', e);
            app.ports.recordingError.send(`Failed to start recording: ${e.message}`);
            isRecording = false;
        }
    });
    
    app.ports.stopRecording.subscribe(() => {
        console.log('Stop recording requested');
        isRecording = false;
        if (recognition) {
            recognition.stop();
        }
    });
});
