# repository-name-placeholder

Labs for `Terraform on Azure Fundamentals` workshop

## Checklist (can be removed from this README before publishing)

- [ ] Download `scripts/bootstrap.ps1` script from this repo and run it on your local machine to:
  - create a new repo from this template and
  - update some parts of the configuration files automatically.
  - commit and push the changes to the new repo.

  _Note: The script is using the `gh` CLI tool, so make sure you have it installed and authenticated._

  ```powershell
  ./bootstrap.ps1 -RepoName <new-repo-name> -WorkshopName "<WORKSHOP_FULL_NAME>"
  ```

  `RepoName` should be a valid GitHub repository name (no spaces, only alphanumeric characters and hyphens). Do not include organization prefix!

  `WorkshopName` is the full name of the workshop, e.g., "DNS Private Resolver Workshop".

- [ ] Create a new **favicon**, and overwrite the current favicon/logo file in `docs/assets/images/logo.svg`.
- [ ] Rename and update the **PowerPoint presentation** with conceptual content in `slides` directory. Update the list of labs and instructions as needed.
- [ ] Export the **title slide** as a PNG file and overwrite `docs/assets/images/logo.png` file. It will be used in the main workshop page.
- [ ] Add `STORAGE_ACCOUNT_SECRET` **secret** to the repository.
- [ ] Update workshop **prerequisites** `docs/prerequisites.md` if needed (should be ok for most labs).
- [ ] Update the **Index** `docs/index.md` - Title, introduction, and agenda
- [ ] Update **lab markdown files** in `docs/labs/` directory following the existing structure.
- [ ] Update the **navigation** in `mkdocs.yml` file (lines 8~9) with the new lab names and the right order.
- [ ] Update **IaC configuration files** (incl. modules) as needed for the given lab.
- [ ] Store **source diagrams** in Draw.io in `docs/assets/visuals.drawio` file.
- [ ] Store **images, diagrams, screenshots** (and other assets) in `docs/assets/images/lab-XX` directories. Update lab markdown files to reference the images correctly.
- [ ] Test the lab instructions end-to-end.
- [ ] Create a Pull Request and merge to `main` branch to publish the lab site.