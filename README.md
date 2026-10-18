# LocalizationScan

Command line tool for projects that use the [`NTDLS.Localization`](https://www.nuget.org/packages/NTDLS.Localization) NuGet package.
It keeps a project's translation database in step with its source code:

1. **Scans** every `*.cs`, `*.cshtml` (ASP.NET views and pages) and `*.razor` file under a folder for the phrases the code asks for, and adds the new ones to the database.
2. **Validates** the translations already in the database and clears the ones that are certainly broken.
3. **Translates** every empty cell, one language at a time (several languages concurrently), and saves each batch as it completes.

It is safe to run repeatedly. Existing, valid translations are never overwritten: only empty cells are filled.

## Usage

```
LocalizationScan <rootPath> <projectName> [concurrency]
```

| Argument | Meaning |
| --- | --- |
| `rootPath` | Folder to scan. Every `*.cs`, `*.cshtml` and `*.razor` file beneath it is read (see [What is scanned](#what-is-scanned)). Typically the solution folder. |
| `projectName` | Project folder under `rootPath` that owns the database, i.e. `<rootPath>\<projectName>\Translations\Translations.db`. |
| `concurrency` | Number of languages translated at the same time. Optional, default `4`. |

Example:

```
dotnet run --project LocalizationScan -c Release -- "C:\Source\MyApp" "MyApp.UI" 8
```

If the database does not exist it is created, with a column for each language supported by `NTDLS.Localization`.
Use `-h` or `--help` to show the usage.

Add the database to the project so it is copied next to the program:

```xml
<None Include="Translations\Translations.db" Condition="Exists('Translations\Translations.db')" CopyToOutputDirectory="PreserveNewest" />
```

### Configuration

Translation uses an Einkr model (`VPT.Einkr.Client`). All settings are optional environment variables:

| Variable | Default | Meaning |
| --- | --- | --- |
| `LOCALIZATION_SCAN_API_KEY` | | The API key. Takes precedence over the key file. |
| `LOCALIZATION_SCAN_KEY_FILE` | `C:\EinkrKey.txt` | A text file containing the API key. |
| `LOCALIZATION_SCAN_MODEL` | `Stratum-27B` | The model used for translation. |
| `LOCALIZATION_SCAN_ESCALATION_MODEL` | none | A larger model. Phrases the primary model cannot translate (after 5 attempts) are handed to it. |

Phrases that still cannot be translated are left empty and are tried again on the next run.

## What is scanned

**Calls in code.** The first argument of each `Localize("...")` call, including formatted text and calls through a localizer:

```csharp
Localize("Search");
Localize("Copied {0} files", count);
Localizer.Default.Localize("Search");
```

Both normal (`"..."`) and verbatim (`@"..."`) strings are found. The argument must be a string literal: a variable or an
interpolated string cannot be scanned. Calls inside comments are ignored.

**Windows Forms designer files.** In `*.Designer.cs`, the text of forms, labels, buttons, check boxes, radio buttons, group boxes, tab pages,
column headers, menu and tool strip items, and the placeholder text of text boxes. (This matches what the localizer translates when a form is
created, so designer text needs no code.)

**Language names.** The names of the supported languages, since they are shown to the user when choosing a language.

**Not scanned.** Folders named `bin`, `obj`, `.git`, `.vs`, `packages`, `Tests`, `LocalizationScan`, `Translations`, `publish`,
and any folder ending in `.Tests`.

## The database

SQLite, table `Translation`:

| Column | Meaning |
| --- | --- |
| `TranslationId` | Row key. |
| `Phrase` | The English text. Unique, ignoring case. This is the key the code looks up. |
| `de`, `fr`, `zh-Hans`, ... | One column per language, named by its culture code. `NULL` or empty means not translated yet. |
| `LastModified` | UTC time the row last changed. Maintained by triggers, so edits made in any tool count. |

An older database is upgraded when the tool runs (old language-name columns are renamed to culture codes, missing language columns and
`LastModified` are added). You can edit translations by hand in any SQLite tool; they are kept as long as they pass validation.

## How translations are checked

A translation is rejected (and retried, or cleared if it is already in the database) when it:

- is empty, or contains the replacement character `U+FFFD`;
- changes, drops or adds a placeholder (`{0}`, `{1:N0}`, `{2,5}`, ...) or has stray braces;
- adds markup (such as `<strong>`) that the English does not have;
- contains letters from the wrong alphabet for the language (for example Cyrillic in an Arabic translation), or mixes alphabets within one word.

Line breaks are normalized to match the phrase.

## Limitations

- Source language is English, and the target languages are the ones `NTDLS.Localization` supports.
- Only C# source is scanned.
- Needs network access and a valid API key. Phrases are sent to the translation service.

## Building

Requires the [.NET 10 SDK](https://dotnet.microsoft.com/download).

```
dotnet build -c Release
```

## License

MIT, see [LICENSE](LICENSE).

## Installer

`Installers\Compile.Release.bat` publishes the tool and builds `Installers\Output\LocalizationScan <version>.exe` with
[Inno Setup 6](https://jrsoftware.org/isinfo.php). The installer needs the .NET 10 runtime on the target machine, and adds the install
folder to the system `PATH` so `LocalizationScan` can be run from anywhere. Keep `AppVersion` in `Installer.iss` in step with the project version.
