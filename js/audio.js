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
        this.speakTimer = null;  // cancel 后延迟朗读的定时器，新语音到来时作废
        this.AudioContextClass = window.AudioContext || window.webkitAudioContext;
        this.audioCtx = null;

        this.initVoice();
    }

    /**
     * 初始化语音
     */
    initVoice() {
        if (!this.synth) return;

        // 部分浏览器语音列表异步加载，加载完成后重新选择
        if ('onvoiceschanged' in this.synth) {
            this.synth.onvoiceschanged = () => this.selectVoice();
        }
        this.selectVoice();
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

        console.debug('Selected voice:', this.voice?.name);
    }

    /**
     * 朗读字符（最新优先：新语音打断旧语音，避免快速操作时发音堆积重叠）
     */
    speak(text, callback) {
        if (!this.enabled || !this.synth) {
            if (callback) callback();
            return;
        }

        const utterance = new SpeechSynthesisUtterance(text);

        if (this.voice) {
            utterance.voice = this.voice;
        }

        utterance.rate = this.rate;
        utterance.pitch = this.pitch;
        utterance.volume = this.volume;
        utterance.lang = 'en-US';

        utterance.onend = () => {
            if (callback) callback();
        };

        utterance.onerror = (e) => {
            // 被打断/取消是预期行为，不算错误
            if (e.error !== 'canceled' && e.error !== 'interrupted') {
                console.error('Speech error:', e);
            }
            if (callback) callback();
        };

        // 丢弃还没播出的旧语音
        if (this.speakTimer) {
            clearTimeout(this.speakTimer);
            this.speakTimer = null;
        }

        if (this.synth.speaking || this.synth.pending) {
            this.synth.cancel();
            // Chrome 在 cancel 后立即 speak 可能吞掉新语音，延迟一拍再朗读
            this.speakTimer = setTimeout(() => {
                this.speakTimer = null;
                this.synth.speak(utterance);
            }, 60);
        } else {
            this.synth.speak(utterance);
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
        if (domino.isAnimal && domino.animalData) {
            this.speakAnimal(domino.animalData, callback);
        } else if (domino.isNumber) {
            this.speakNumber(domino.character, callback);
        } else {
            this.speakLetter(domino.character, callback);
        }
    }

    /**
     * 朗读动物英文名
     */
    speakAnimal(animalData, callback) {
        this.speak(animalData.name, callback);
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
            const audioCtx = this.getAudioContext();
            if (!audioCtx) return;

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
     * 复用同一个 AudioContext，避免频繁创建上下文
     */
    getAudioContext() {
        if (!this.AudioContextClass) return null;

        if (!this.audioCtx || this.audioCtx.state === 'closed') {
            this.audioCtx = new this.AudioContextClass();
        }

        if (this.audioCtx.state === 'suspended') {
            this.audioCtx.resume();
        }

        return this.audioCtx;
    }

    /**
     * 设置是否启用
     */
    setEnabled(enabled) {
        this.enabled = enabled;
        if (!enabled) {
            this.clear();
        }
    }

    /**
     * 停止当前朗读并丢弃待播语音
     */
    clear() {
        if (this.speakTimer) {
            clearTimeout(this.speakTimer);
            this.speakTimer = null;
        }
        if (this.synth) {
            this.synth.cancel();
        }
    }
}

// 导出类
if (typeof module !== 'undefined' && module.exports) {
    module.exports = AudioManager;
}
