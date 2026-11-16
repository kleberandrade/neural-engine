# Architecture / Arquitetura

The implementation is organized by responsibility, not a single file per model
family. The stable consumer entry point is `package:neural_engine/neural_engine.dart`.
Internal files are not a compatibility contract.

| Document | Contents |
| --- | --- |
| [Overview / Visão geral](architecture/overview.md) | Boundaries, dependencies, design decisions |
| [Source structure / Estrutura](architecture/structure.md) | Folder map, class ownership, extension rules |
| [Class diagrams / Diagramas de classes](architecture/class_diagrams.md) | Actual interfaces, implementations and collaborators |
| [Training and numerical behavior](architecture/training.md) | Shared lifecycle, gradient flow, state and validation |
| [Model formats](architecture/model_formats.md) | Parameter layout, JSON and compatibility |
| [Portuguese model tutorials](models.pt-BR.md) | Worked examples and experiments |
| [English model tutorials](models.md) | Worked examples and experiments |

The documents describe implemented code. Plans are explicitly marked in the
model guides and release notes; no class in a diagram is merely aspirational.
