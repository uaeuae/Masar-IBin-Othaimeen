package app.othaimeen.masar

import com.ryanheise.audioservice.AudioServiceActivity

// AudioServiceActivity keeps the media session alive when the activity is
// backgrounded — required by just_audio_background.
class MainActivity : AudioServiceActivity()
