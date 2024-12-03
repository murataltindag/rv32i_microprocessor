# Pipelined Microprocessor Design - RV32I Implementation

This repository contains the implementation and detailed documentation of a pipelined microprocessor designed to execute the RV32I instruction set. The project was developed as part of ECE 411: Computer Organization and Design and provides insights into pipelined microprocessor architecture, optimization techniques, and associated challenges.

---

## Introduction

The goal of this project was to design and optimize a pipelined microprocessor to enhance understanding of microprocessor design principles. The implementation involved:

- Developing a 5-stage pipeline microprocessor for the RV32I instruction set.
- Tackling standard pipelining challenges like data hazards, control hazards, and performance bottlenecks.
- Incorporating advanced features like a memory hierarchy, branch predictors, and prefetching mechanisms for optimization.

---

## Project Overview

The project was structured into four major checkpoints:
1. **Baseline Design**: Initial 5-stage pipeline with basic functionality.
2. **Memory Hierarchy and Hazard Detection**: Integration of instruction/data caches and hazard management.
3. **Advanced Features**: Addition of branch prediction, an L2 cache, and hardware prefetching.
4. **Design Competition**: Final optimization and synthesis of the complete design.

Key features:
- Implements RV32I (excluding FENCE*, ECALL, EBREAK, and CSRR instructions).
- Modularity for ease of testing and integration of various components.
- Optimized memory hierarchy and branch prediction.

---

## Features and Design Details

### Pipeline Stages
1. **Fetch**: Fetches instructions and updates the program counter.
2. **Decode**: Decodes instructions into their respective components.
3. **Execute**: Executes arithmetic, logical operations, and branch decisions.
4. **Memory Access**: Reads and writes to data memory.
5. **Write-Back**: Updates the destination register with computed results.

### Advanced Features
1. **Branch Prediction**:
   - Local history-based predictor using a 2-bit state machine.
   - Branch Target Buffer (BTB) for efficient branch target predictions.

2. **Memory Hierarchy**:
   - Direct-mapped L1 caches and a unified 8-way set-associative L2 cache.
   - Prefetching with a tagged stream buffer to reduce cache misses.
   - Evaluation of eviction write buffers for optimization.

3. **Hazard Management**:
   - Data forwarding to mitigate data hazards.
   - Static not-taken branch predictor for control hazards.

---

## Performance Analysis

- **Branch Predictor**:
  - Achieved an average speedup of ~1.76× compared to static prediction.
  - Average accuracy below 80% due to limited local history utilization.

- **L2 Cache**:
  - Reduced memory access latency with an average speedup of ~5.15×.
  - Increased power consumption and area due to higher complexity.

- **Prefetching**:
  - Minimal impact due to correctness issues and low branch locality.

---

## Final Design Highlights

- Modular architecture enabling easy feature integration and testing.
- Parameterized L2 cache supporting future scalability.
- Competitive performance with significant speedups from branch prediction and memory hierarchy.

---

## Future Work

Further optimizations could include:
- Enhanced verification tools for debugging and performance analysis.
- Improved branch predictors leveraging global history.
- Exploration of varying cache line sizes for better cache utilization.

---

## References

1. Hennessy, J., Patterson, D. (2014). *Computer Architecture: A Quantitative Approach*.
2. Jouppi, N. (1990). *Improving Direct-Mapped Cache Performance by the Addition of a Small Fully-Associative Cache and Prefetch Buffers*.

---

## Team

- Murat Altindag
- Xinpei Jiang
- Kelsey Chang
