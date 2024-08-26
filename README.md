#  Profiling .mlmodelc models, compiled MLProgram, in remote AAR (Apple Archive)

1. Xcode Peformace Tab only works for .mlmodel or .mlpacakage models
2. Core ML's [MLComputePlan](https://developer.apple.com/documentation/coreml/mlcomputeplan) only reports relatevie compute cost
3. I hacked a bit and figured how to run per-op profiling and get analytics.mil
4. with that, we can check per-op analytics of .mlmodelc models
