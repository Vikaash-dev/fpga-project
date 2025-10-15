#!/usr/bin/env python3
"""
Audio Event Detection Model Generator
Generates quantized 4-bit weights for CNN accelerator
"""

import numpy as np
import json

class AudioEventModel:
    def __init__(self, num_mfcc=13, conv_filters=8, kernel_size=3, num_classes=4):
        self.num_mfcc = num_mfcc
        self.conv_filters = conv_filters
        self.kernel_size = kernel_size
        self.num_classes = num_classes
        
    def quantize_4bit(self, weights):
        """Quantize weights to 4-bit signed integers (-8 to 7)"""
        # Scale to [-8, 7] range
        w_min, w_max = weights.min(), weights.max()
        if w_max - w_min > 0:
            weights_scaled = (weights - w_min) / (w_max - w_min) * 15 - 8
        else:
            weights_scaled = np.zeros_like(weights)
        
        # Quantize
        weights_quant = np.clip(np.round(weights_scaled), -8, 7).astype(np.int8)
        return weights_quant
    
    def generate_random_model(self):
        """Generate random quantized weights for demonstration"""
        np.random.seed(42)
        
        # Convolution weights: [conv_filters, kernel_size]
        conv_weights = np.random.randn(self.conv_filters, self.kernel_size)
        conv_weights_quant = self.quantize_4bit(conv_weights)
        
        # Fully connected weights: [num_classes, conv_filters]
        fc_weights = np.random.randn(self.num_classes, self.conv_filters)
        fc_weights_quant = self.quantize_4bit(fc_weights)
        
        # Biases
        fc_bias = np.random.randn(self.num_classes) * 10
        fc_bias_quant = np.clip(np.round(fc_bias), -128, 127).astype(np.int8)
        
        return {
            'conv_weights': conv_weights_quant.tolist(),
            'fc_weights': fc_weights_quant.tolist(),
            'fc_bias': fc_bias_quant.tolist()
        }
    
    def generate_verilog_weights(self, weights_dict, output_file):
        """Generate Verilog initialization code for weights"""
        with open(output_file, 'w') as f:
            f.write("// Auto-generated quantized weights for CNN accelerator\n\n")
            
            # Convolution weights
            f.write("// Convolution weights initialization\n")
            for i, filter_weights in enumerate(weights_dict['conv_weights']):
                for j, w in enumerate(filter_weights):
                    f.write(f"conv_weights[{i}][{j}] = 4'sd{w};\n")
            f.write("\n")
            
            # FC weights
            f.write("// Fully connected weights initialization\n")
            for i, class_weights in enumerate(weights_dict['fc_weights']):
                for j, w in enumerate(class_weights):
                    f.write(f"fc_weights[{i}][{j}] = 4'sd{w};\n")
            f.write("\n")
            
            # FC bias
            f.write("// Fully connected bias initialization\n")
            for i, b in enumerate(weights_dict['fc_bias']):
                f.write(f"fc_bias[{i}] = 8'sd{b};\n")
    
    def save_model(self, weights_dict, json_file):
        """Save model weights to JSON file"""
        with open(json_file, 'w') as f:
            json.dump(weights_dict, f, indent=2)
        print(f"Model saved to {json_file}")

def main():
    print("Generating Audio Event Detection Model...")
    
    # Create model
    model = AudioEventModel(num_mfcc=13, conv_filters=8, kernel_size=3, num_classes=4)
    
    # Generate weights
    weights = model.generate_random_model()
    
    # Save as JSON
    model.save_model(weights, 'model_weights.json')
    
    # Generate Verilog initialization
    model.generate_verilog_weights(weights, 'model_weights_init.v')
    print("Verilog initialization code generated")
    
    # Print statistics
    print("\nModel Statistics:")
    print(f"  Convolution filters: {model.conv_filters}")
    print(f"  Kernel size: {model.kernel_size}")
    print(f"  Input features (MFCC): {model.num_mfcc}")
    print(f"  Output classes: {model.num_classes}")
    print(f"  Total conv weights: {model.conv_filters * model.kernel_size}")
    print(f"  Total FC weights: {model.num_classes * model.conv_filters}")
    print(f"  Weight bit-width: 4-bit")
    
    # Calculate approximate memory footprint
    conv_bits = model.conv_filters * model.kernel_size * 4
    fc_bits = model.num_classes * model.conv_filters * 4
    bias_bits = model.num_classes * 8
    total_bits = conv_bits + fc_bits + bias_bits
    
    print(f"\nMemory Footprint:")
    print(f"  Conv weights: {conv_bits} bits ({conv_bits/8:.1f} bytes)")
    print(f"  FC weights: {fc_bits} bits ({fc_bits/8:.1f} bytes)")
    print(f"  FC bias: {bias_bits} bits ({bias_bits/8:.1f} bytes)")
    print(f"  Total: {total_bits} bits ({total_bits/8:.1f} bytes)")

if __name__ == "__main__":
    main()
