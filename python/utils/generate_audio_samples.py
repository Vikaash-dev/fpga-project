#!/usr/bin/env python3
"""
Audio Sample Generator for Testing
Generates test audio samples with different event types
"""

import numpy as np
import wave
import struct

class AudioSampleGenerator:
    def __init__(self, sample_rate=16000, duration=1.0):
        self.sample_rate = sample_rate
        self.duration = duration
        self.num_samples = int(sample_rate * duration)
        
    def generate_silence(self, noise_level=100):
        """Generate background noise / silence"""
        samples = np.random.randint(-noise_level, noise_level, self.num_samples)
        return samples.astype(np.int16)
    
    def generate_tone(self, frequency, amplitude=10000):
        """Generate a pure tone"""
        t = np.linspace(0, self.duration, self.num_samples)
        samples = amplitude * np.sin(2 * np.pi * frequency * t)
        return samples.astype(np.int16)
    
    def generate_door_slam(self):
        """Simulate a door slam (low frequency impulse)"""
        t = np.linspace(0, self.duration, self.num_samples)
        # Decaying low frequency burst
        envelope = np.exp(-20 * t)
        samples = 15000 * envelope * np.sin(2 * np.pi * 100 * t)
        return samples.astype(np.int16)
    
    def generate_alarm(self):
        """Simulate an alarm sound (alternating tones)"""
        t = np.linspace(0, self.duration, self.num_samples)
        # Alternating between two frequencies
        freq_modulation = 800 + 400 * np.sin(2 * np.pi * 4 * t)
        samples = 12000 * np.sin(2 * np.pi * freq_modulation * t)
        return samples.astype(np.int16)
    
    def generate_whistle(self):
        """Simulate a whistle (high frequency tone)"""
        t = np.linspace(0, self.duration, self.num_samples)
        # High frequency with slight frequency modulation
        freq = 3000 + 200 * np.sin(2 * np.pi * 5 * t)
        samples = 10000 * np.sin(2 * np.pi * freq * t)
        return samples.astype(np.int16)
    
    def save_wav(self, samples, filename):
        """Save samples to WAV file"""
        with wave.open(filename, 'w') as wav_file:
            wav_file.setnchannels(1)  # Mono
            wav_file.setsampwidth(2)  # 16-bit
            wav_file.setframerate(self.sample_rate)
            
            # Convert samples to bytes
            for sample in samples:
                wav_file.writeframes(struct.pack('h', sample))
        
        print(f"Saved {filename}")
    
    def save_verilog_testdata(self, samples, filename):
        """Save samples as Verilog test data"""
        with open(filename, 'w') as f:
            f.write("// Auto-generated test audio samples\n")
            f.write(f"// Sample rate: {self.sample_rate} Hz\n")
            f.write(f"// Duration: {self.duration} s\n")
            f.write(f"// Number of samples: {len(samples)}\n\n")
            
            for i, sample in enumerate(samples):
                f.write(f"audio_samples[{i}] = 16'sd{sample};\n")
        
        print(f"Saved Verilog test data to {filename}")

def main():
    print("Generating Audio Test Samples...")
    
    generator = AudioSampleGenerator(sample_rate=16000, duration=1.0)
    
    # Generate different event types
    print("\nGenerating samples:")
    
    # Class 0: Background noise
    silence = generator.generate_silence(noise_level=100)
    generator.save_wav(silence, 'test_audio_class0_silence.wav')
    
    # Class 1: Door slam (low frequency)
    door_slam = generator.generate_door_slam()
    generator.save_wav(door_slam, 'test_audio_class1_doorslam.wav')
    
    # Class 2: Alarm (mid frequency)
    alarm = generator.generate_alarm()
    generator.save_wav(alarm, 'test_audio_class2_alarm.wav')
    
    # Class 3: Whistle (high frequency)
    whistle = generator.generate_whistle()
    generator.save_wav(whistle, 'test_audio_class3_whistle.wav')
    
    # Generate Verilog test data (shorter samples for simulation)
    short_gen = AudioSampleGenerator(sample_rate=16000, duration=0.1)  # 100ms
    
    test_samples = {
        'silence': short_gen.generate_silence(noise_level=100),
        'doorslam': short_gen.generate_door_slam(),
        'alarm': short_gen.generate_alarm(),
        'whistle': short_gen.generate_whistle()
    }
    
    # Save a subset for Verilog simulation
    for name, samples in test_samples.items():
        # Take only first 256 samples for quick simulation
        short_gen.save_verilog_testdata(
            samples[:256], 
            f'test_audio_{name}.vh'
        )
    
    print("\nTest sample generation completed!")
    print("\nClass mapping:")
    print("  Class 0: Background noise / Silence")
    print("  Class 1: Door slam (Low frequency event)")
    print("  Class 2: Alarm (Mid frequency event)")
    print("  Class 3: Whistle (High frequency event)")

if __name__ == "__main__":
    main()
