# Gainz

Minimal-friction strength coaching that feels like Apple built a Whoop-grade training lab right into your phone.

## What this repo contains
- **App** — Swift + SwiftUI iOS target, scoped for watchOS & visionOS extensions.
- **CoreKit** — domain layer that models workouts, mesocycles, recovery scores, and HRV metrics.
- **Analytics** — Neural-powered insight engine (LSTM + Transformer hybrids) streaming to the in-app dashboard.
- **DesignSystem** — Typography, spacing, color tokens, and the gradient engine behind the phoenix-wing aesthetic.
- **Scripts** — Fastlane lanes, GitHub Actions, SwiftLint/SwiftFormat hooks, and one-touch bootstrap scripts.

## Quick start
1. **Clone**  
   `git clone https://github.com/your-org/gainz.git && cd gainz`
2. **Bootstrap** (installs Xcode tools, SwiftLint/SwiftFormat, pre-commit hooks)  
   `./Scripts/bootstrap.sh`
3. **Run**  
   `open Gainz.xcodeproj` → ⌘R
4. **Test**  
   `make test` (runs XCTest + snapshot + integration suites)
5. **Ship beta**  
   `bundle exec fastlane ios beta` (uploads to TestFlight)

## Architecture at a glance
- Clean Swift + modular SPM packages  
- MVVM + Combine flows with an event-driven CoreData/CloudKit store  
- Functional reactive pipelines for HealthKit feeds  
- Local inference via Core ML; remote inference via serverless Swift functions  

## Contributing
- Follow **Conventional Commits** (`feat:`, `fix:`…) and **Semantic Versioning**.
- Run `make lint` before every PR; CI enforces zero warnings and >90 % test coverage.
- Open an Issue or Discussion for feature proposals; PRs require at least one approving review.

## Roadmap
- watchOS companion (stand-alone logging, haptic cues)  
- Adaptive deload scheduling via Bayesian HRV models  
- Android & Web front-ends (KMP + React)  
- Public GraphQL API for third-party integrations

## License
Gainz is released under the Apache 2.0 license. See `LICENSE` for details.

## Contact
Built with ❤️ by Brody Hiland and contributors. Reach us at `dev@gainz.app`.

