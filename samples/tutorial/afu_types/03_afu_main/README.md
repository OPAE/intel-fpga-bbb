# Native afu\_main\(\) AFUs

Like the [hybrid section](../02_hybrid), this tutorial section applies only to OFS systems. The RTL currently compiles on d5005 and n6000 reference platforms. The limited system support is a design choice: the *afu\_main\(\)* top-level module port list varies from platform to platform.

AFUs implemented to native FIM interfaces are responsible for matching platform-specific FIM protocols. The build and simulation environments are identical to PIM-based AFUs, described in [Section 1](../01_pim_ifc). The JSON file structure is the same, as is user clock frequency constraint.

Currently, a single native [hello\_world](hello_world) is present in the tutorial. Many of the exercisers in the base FIM build are also implemented to native FIM interfaces.