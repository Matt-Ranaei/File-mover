```markdown
# File Mover Script

A Zsh-based utility to move or copy files of specified extensions from one or more source directories into a single destination directory, with optional progress reporting and file-list output.

## Repository Structure

```

file-mover/
├── file\_mover.zsh       # Main script
├── README.md            # This documentation
├── .gitignore           # Standard ignores (e.g., list-files.txt)
└── LICENSE              # MIT License

````

## Features

- Accepts multiple source directories (comma‑separated).
- Filters by one or more file extensions (or `all` files).
- Automatically creates a destination directory if needed.
- Choice of moving vs. copying files.
- Detailed vs. single‑bar progress display.
- Renames collisions with timestamp prefixes.
- Optionally generates `list-files.txt` of processed file names.

## Usage

1. Make the script executable:
   ```bash
   chmod +x file_mover.zsh
````

2. Run:

   ```bash
   ./file_mover.zsh
   ```
3. Follow the interactive prompts:

   * **Source directories**: e.g. `~/Documents, /mnt/usb`
   * **Extensions**: `jpg,png` or `all`
   * **Destination**: e.g. `~/Pictures/Collected`
   * **Move or copy**: `m` or `c`
   * **Display mode**: `d` (verbose) or `s` (single progress bar)
   * **Save list**: `y` to write `list-files.txt` in the destination

## Code Walkthrough

1. **Help & Banner** (`show_help` & initial echoes)

   * Displays usage instructions and header.

2. **Input & Validation**

   * Reads comma‑separated source directories; trims whitespace.
   * `validate_directory` ensures each exists; invalid ones are skipped.

3. **Extension Parsing**

   * If `all`, processes every file.
   * Else, splits extensions, normalizes to dot‑prefixed (e.g. `.txt`).

4. **Destination Handling**

   * Validates or offers to create the destination directory.
   * Resolves to absolute path.

5. **Operation Choice**

   * Move (`mv`) vs. copy (`cp`), tracked by `move_files` flag.

6. **Progress Configuration**

   * Verbose (`-v`) vs. concise bar; `show_progress` prints a 50‑char bar.

7. **Counting Phase**

   * First pass: uses `find` to count matching files for progress total.

8. **Processing Phase**

   * Constructs `find` command dynamically based on extensions.
   * For each file:

     * Builds destination filename; prefixes timestamp on collisions.
     * Executes `mv` or `cp`, records errors.
     * Updates progress display.

9. **Output & List File**

   * Summarizes processed vs. errored counts.
   * Optionally writes `list-files.txt` with all moved/copied basenames.

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Commit your changes
4. Submit a Pull Request

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

```
```
