# **dir2sh**  

**Embed directory content into a bash script (stores directory content inside a shell script in a compressed format)**


This Linux/macOS utility embeds the contents of a directory into a shell script in a compressed format. The resulting script can be transferred to another system, and by simply executing it, the directory is recreated. This approach is particularly useful when a single executable file (such as an installer) needs to be transported, which contains both the data and the installation instructions in one file.

---

## **How it Works**

1. The input directory (let's call it `IN`) is converted into a tar.gz file (`IN.tar.gz`).
2. The tar.gz file (`IN.tar.gz`) is then embedded into a Bash script (`OUT.tar.sh`) with a self-extraction feature.
3. The self-extractable tar script (`OUT.tar.sh`) can be transferred to any Linux/macOS computer/device, where it can be extracted.

---

## **How to Extract the Directory (IN) from the Tar Script (OUT.tar.sh)**

1. Execute the following command:

   ```bash
   ./OUT.tar.sh
   ```

2. The directory (`IN`) will be extracted in the current working directory.

---

## **Installation**

```bash
sudo ./install.sh  # If you have root permissions, you can execute ./install.sh directly.
```

---

## **Uninstallation**

```bash
sudo ./uninstall.sh  # If you have root permissions, you can execute ./uninstall.sh directly.
```

---

## **Usage**

```bash
$ dir2sh <directory_name> <output_script_name>
```

### **Example 1**

```bash
$ dir2sh /home/test test.tar.sh
```

This command compresses the directory `/home/test` into `test.tar.sh`.

### **Example 2**

```bash
$ dir2sh "*" curr_dir.tar.sh
```

This command compresses all contents of the current directory into `curr_dir.tar.sh`.

---

## **Use Case**

This utility is ideal for transporting directories as a self-extractable package/script between Linux/macOS systems. It is especially useful for scenarios where you need to distribute a single executable file (like an installer) that contains both the data and the instructions for installation, allowing the user to extract and install the directory with just one command.
