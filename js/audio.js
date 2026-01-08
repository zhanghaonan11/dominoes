/**
 * 音频管理器 - 使用 Web Speech API 朗读字母和数字
 */
class AudioManager {
    constructor() {
        this.synth = window.speechSynthesis;
        this.enabled = true;
        this.rate = 0.8;      // 语速（慢一点，适合小孩）
        this.pitch = 1.2;     // 音调（稍高，更活泼）
        this.volume = 1.0;
        this.voice = null;
        this.queue = [];
        this.isSpeaking = false;

        this.initVoice();
    }

    /**
     * 初始化语音
     */
    initVoice() {
        // 等待语音列表加载
        if (this.synth.onvoiceschanged !== undefined) {
            this.synth.onvoiceschanged = () => this.selectVoice();
        }
        // 尝试立即选择
        setTimeout(() => this.selectVoice(), 100);
    }

    /**
     * 选择合适的英语语音
     */
    selectVoice() {
        const voices = this.synth.getVoices();

        // 优先选择英语语音
        const englishVoices = voices.filter(v =>
            v.lang.startsWith('en') && v.localService
        );

        // 尝试找一个女声（通常更适合小朋友）
        this.voice = englishVoices.find(v =>
            v.name.toLowerCase().includes('female') ||
            v.name.toLowerCase().includes('samantha') ||
            v.name.toLowerCase().includes('victoria')
        ) || englishVoices[0] || voices[0];

        console.log('Selected voice:', this.voice?.name);
    }

    /**
     * 朗读字符
     */
    speak(text, callback) {
        if (!this.enabled || !this.synth) {
            if (callback) callback();
            return;
        }

        // 取消之前的语音
        // this.synth.cancel();

        const utterance = new SpeechSynthesisUtterance(text);

        if (this.voice) {
            utterance.voice = this.voice;
        }

        utterance.rate = this.rate;
        utterance.pitch = this.pitch;
        utterance.volume = this.volume;
        utterance.lang = 'en-US';

        utterance.onend = () => {
            this.isSpeaking = false;
            if (callback) callback();
            this.processQueue();
        };

        utterance.onerror = (e) => {
            console.error('Speech error:', e);
            this.isSpeaking = false;
            if (callback) callback();
            this.processQueue();
        };

        if (this.isSpeaking) {
            this.queue.push({ text, callback, utterance });
        } else {
            this.isSpeaking = true;
            this.synth.speak(utterance);
        }
    }

    /**
     * 处理语音队列
     */
    processQueue() {
        if (this.queue.length > 0 && !this.isSpeaking) {
            const next = this.queue.shift();
            this.isSpeaking = true;
            this.synth.speak(next.utterance);
        }
    }

    /**
     * 朗读字母
     */
    speakLetter(letter, callback) {
        // 使用小写字母，避免读成 "capital A"
        const text = letter.toLowerCase();
        this.speak(text, callback);
    }

    /**
     * 朗读数字
     */
    speakNumber(number, callback) {
        // 只发音数字本身
        const text = number.toString();
        this.speak(text, callback);
    }

    /**
     * 朗读骨牌上的字符
     */
    speakDomino(domino, callback) {
        if (domino.isNumber) {
            this.speakNumber(domino.character, callback);
        } else {
            this.speakLetter(domino.character, callback);
        }
    }

    /**
     * 播放庆祝语音
     */
    speakCelebration() {
        const celebrations = [
            'Wonderful!',
            'Great job!',
            'Amazing!',
            'You did it!',
            'Fantastic!'
        ];
        const text = celebrations[Math.floor(Math.random() * celebrations.length)];
        this.speak(text);
    }

    /**
     * 播放简单音效（使用 Web Audio API）
     */
    playSound(type) {
        try {
            const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
            const oscillator = audioCtx.createOscillator();
            const gainNode = audioCtx.createGain();

            oscillator.connect(gainNode);
            gainNode.connect(audioCtx.destination);

            switch (type) {
                case 'click':
                    oscillator.frequency.value = 800;
                    gainNode.gain.setValueAtTime(0.3, audioCtx.currentTime);
                    gainNode.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + 0.1);
                    oscillator.start(audioCtx.currentTime);
                    oscillator.stop(audioCtx.currentTime + 0.1);
                    break;

                case 'fall':
                    oscillator.frequency.value = 200;
                    oscillator.frequency.exponentialRampToValueAtTime(100, audioCtx.currentTime + 0.15);
                    gainNode.gain.setValueAtTime(0.2, audioCtx.currentTime);
                    gainNode.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + 0.15);
                    oscillator.start(audioCtx.currentTime);
                    oscillator.stop(audioCtx.currentTime + 0.15);
                    break;

                case 'celebrate':
                    // 播放一系列上升音符
                    const notes = [523, 659, 784, 1047]; // C5, E5, G5, C6
                    notes.forEach((freq, i) => {
                        const osc = audioCtx.createOscillator();
                        const gain = audioCtx.createGain();
                        osc.connect(gain);
                        gain.connect(audioCtx.destination);
                        osc.frequency.value = freq;
                        gain.gain.setValueAtTime(0.2, audioCtx.currentTime + i * 0.15);
                        gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + i * 0.15 + 0.3);
                        osc.start(audioCtx.currentTime + i * 0.15);
                        osc.stop(audioCtx.currentTime + i * 0.15 + 0.3);
                    });
                    break;
            }
        } catch (e) {
            console.log('Audio not supported:', e);
        }
    }

    /**
     * 设置是否启用
     */
    setEnabled(enabled) {
        this.enabled = enabled;
        if (!enabled) {
            this.synth.cancel();
            this.queue = [];
        }
    }

    /**
     * 清空队列
     */
    clear() {
        this.synth.cancel();
        this.queue = [];
        this.isSpeaking = false;
    }
}

// 导出类
if (typeof module !== 'undefined' && module.exports) {
    module.exports = AudioManager;
}
