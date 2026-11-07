# Contributing

This page covers contributions to the documentation. Code contribution rules are in `CONTRIBUTING.md` at the repository root.

## Documentation standards

| Rule | Detail |
|---|---|
| Structure | Every page appears in `docs/SUMMARY.md`. A new section has a `README.md` landing page |
| References | Every page ends with a **References** section citing Microsoft Learn pages that the content follows |
| Links | Internal links are relative (`../identity/pim.md`); external Microsoft links use `https://learn.microsoft.com/en-us/...` |
| Diagrams | Mermaid in fenced `mermaid` blocks so they render on GitBook and GitHub. Quote labels that contain punctuation; avoid parentheses in unquoted labels |
| GitBook blocks | Hint blocks for warnings and notes, stepper blocks for procedures, tabs blocks for alternatives |
| Names | Stack, workflow, secret and variable names exactly as in the code, in backticks |
| Placeholders | `contoso.com`, `<owner>/<repo>`, never real tenant IDs, domains or user names |
| Tone | Plain, direct, British English spelling, present tense |

## Page template

```markdown
# Page title

One paragraph on what this page is for and who uses it.

## Section

Content, tables, diagrams and GitBook hint or stepper blocks.

## References

* [Microsoft Learn page title](https://learn.microsoft.com/en-us/...)
```

## Adding an ADR

Copy the template from [Architecture decision records](architecture/adr/README.md), number it sequentially, add it to the ADR index table and to `docs/SUMMARY.md`.

## Checks

`ci-quality.yml` runs markdown lint and a link check over `docs/` on every pull request. Run the same checks locally with pre-commit before pushing.

## References

* [Microsoft Entra deployment plans](https://learn.microsoft.com/en-us/entra/architecture/deployment-plans)
