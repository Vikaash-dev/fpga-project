# Contributing to Audio Event Detection VLSI Architecture

Thank you for your interest in contributing to this project! This document provides guidelines for contributing.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/fpga-project.git`
3. Create a branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Test your changes
6. Commit and push
7. Open a Pull Request

## Development Setup

### Prerequisites

```bash
# Install simulation tools
sudo apt-get install iverilog gtkwave

# Install Python dependencies
pip install -r requirements.txt
```

### Building the Project

```bash
# Run all simulations
make sim

# Run specific testbench
make sim_mac
make sim_prep
make sim_top

# Generate model weights
make gen_model

# Generate test audio
make gen_audio
```

## Code Style Guidelines

### Verilog/SystemVerilog

- Use 4-space indentation
- Include module headers with description
- Use meaningful signal names
- Add comments for complex logic
- Follow naming conventions:
  - Signals: `snake_case`
  - Parameters: `UPPER_CASE`
  - Modules: `snake_case_module`

Example:
```verilog
/*
 * Module Description
 * Brief explanation of functionality
 */
module example_module #(
    parameter DATA_WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out
);
    // Implementation
endmodule
```

### Python

- Follow PEP 8 style guide
- Use type hints where appropriate
- Include docstrings for functions
- Write unit tests for new functionality

Example:
```python
def process_audio(samples: np.ndarray, sample_rate: int) -> np.ndarray:
    """
    Process audio samples.
    
    Args:
        samples: Input audio samples
        sample_rate: Sample rate in Hz
        
    Returns:
        Processed audio samples
    """
    # Implementation
    return processed_samples
```

## Testing

### RTL Testing

All new RTL modules must include testbenches:

1. Create testbench in appropriate `tb/` subdirectory
2. Test all major functionality
3. Include edge cases
4. Add waveform dumps for debugging

### Python Testing

For Python code:
```bash
python -m pytest tests/
```

## Commit Guidelines

- Write clear, descriptive commit messages
- Use present tense ("Add feature" not "Added feature")
- Reference issues when applicable
- Keep commits focused and atomic

Example:
```
Add noise gate filtering to preprocessor

- Implement threshold-based noise gate
- Add configurable threshold parameter
- Update testbench with noise gate tests

Fixes #123
```

## Pull Request Process

1. **Update Documentation**: Ensure README and relevant docs are updated
2. **Add Tests**: Include testbenches or unit tests
3. **Run All Tests**: Verify nothing breaks
4. **Update CHANGELOG**: Add entry describing changes
5. **Request Review**: Tag relevant maintainers

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement

## Testing
Describe testing performed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] Tests added/updated
- [ ] All tests pass
```

## Areas for Contribution

### High Priority
- [ ] Hardware validation on FPGA boards
- [ ] Power consumption measurements
- [ ] Classification accuracy improvements
- [ ] Real-world audio dataset testing

### Medium Priority
- [ ] Additional audio event classes
- [ ] True FFT/MFCC implementation
- [ ] Timing optimization
- [ ] Resource utilization optimization

### Low Priority
- [ ] Additional target FPGA families
- [ ] GUI for model training
- [ ] Real-time visualization tools
- [ ] Documentation improvements

## Reporting Issues

### Bug Reports

Include:
- Clear description of the bug
- Steps to reproduce
- Expected vs actual behavior
- Environment details (OS, tool versions)
- Relevant logs or error messages

### Feature Requests

Include:
- Clear description of the feature
- Use case and motivation
- Proposed implementation (if any)
- Potential impact on existing code

## Questions?

- Open an issue with the "question" label
- Check existing documentation
- Review closed issues for similar questions

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inspiring community for all.

### Expected Behavior

- Be respectful and inclusive
- Accept constructive criticism gracefully
- Focus on what's best for the community
- Show empathy towards others

### Unacceptable Behavior

- Harassment or discriminatory language
- Trolling or insulting comments
- Personal or political attacks
- Publishing others' private information

## Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes
- Project documentation

Thank you for contributing to this project! 🎉
