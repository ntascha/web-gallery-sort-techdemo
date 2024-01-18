# web-gallery-sort
Authors: Allyssa Ulz, Monika Popic, Natascha Baumgartner

## Description
In this project a script has been written that remembers when it was last executed.
All uploaded images are scaled down to a reasonable resolution (e.g. max. 320x200), watermarked and are then uploaded to https://eine-firma.de/myimages/gallery.html. 
In this website the images are in a table next to the pictures there are also some information about the image like the date and time when the image was downloaded, the name of the image and the size.

## Webserver 
A web server is a computer that is responsible for serving web pages to clients. When a client, such as a web browser, requests a web page from a server, the server sends the page back to the client. The process of a server sending a web page to a client is called "serving" the page. Web servers can be used to host websites or other applications that are accessible over the internet. Web servers are typically connected to the internet and listen for requests from clients, and they can serve web pages, as well as other types of data, such as images, videos, and API responses.

In this case we used https://eine-firma.de/myimages/gallery.html

## What does our script do?
The script will iterate through all the image files in the directory var/www/html/wordpress/myimages, scale them down if necessary, add a watermark, and overwrite the watermarked images in the "myimages" directory. It will also copy gallery.html to the "public" directory. It will write the current time to a file called "last_run.txt", which will allow you to remember when the script was last run.

## Dependencies
* Visual Studio Code
* Bash

## How to start the ssh server

```
ssh username@eine-firma.de
```

## How to start the script
To start the bash program, you can make the script executable:

```
chmod +x web-gallery-sort.sh
```

Then it´s important to download the imagemagick package. This package is used to get the size or the name of a picture.

Windows: 
```
sudo apt-get install imagemagick
```

MacOS:
```
brew install imagemagick
```

After that you can start the script with the following command:

```
./web-gallery-sort.sh
```

## How the script works

- At the top of the Script we have initialized hostname, username, and web directory of the remote server
- the commands scp are used to copy the files from the local machine to the remote server and so that the output is not in the console, it is written into an output.txt file
- if somebody else uses the script, you need to change the username to your lastname
```bash
hostname=eine-firma.de
username=popic
web_dir=/var/www/html/wordpress/myimages
watermark="Copyright.png"

scp -r "css" "$username@$hostname:$web_dir" > output.txt
scp "$watermark" "$username@$hostname:$web_dir" > output.txt
```

- We get the current date with **$(date)** and safe this in **current_time**.

```bash
current_time=$(date)
```

- We check if a file named "last_run.txt" exists, if the file exists, the script read the contents of the file and store it in the variable **last_run**. Then we print the last time the script was run. If the file doesn't exists, the script create it and write the current date and time in the file.

```bash
# Check if a file named "last_run.txt" exists
if [ -f "last_run.txt" ]; then
  # If the file exists, read the contents of the file and store it in a variable
  last_run=$(cat last_run.txt)

  # Print the last time the script was run
  echo "Last run: $last_run"
else
  # If the file doesn't exist, create it and write the current date and time to it
  echo "$current_time" > last_run.txt
fi
```

- The script updates the "last_run.txt" file with the current date and time

```bash
echo "$current_time" > last_run.txt
```

- Here we set the maximum width and height for the picture and for our watermark

```bash
# Set the maximum width and height
max_width=320
max_height=200
# Set the maximum width and height for watermark
width_watermark=100
height_watermark=100
```

- We safe the "Copyright.png" (our watermark) in the watermark variable

```bash
watermark="Copyright.png"
```

- To find all imgaes in the current direcotry and its subdirecotries
- Then check if the images need to be resized and resize them if necessary
- Then add the watermark to the images and put in on the position SouthEast (bottom right corner) and overwrite the old picture without the watermark
- mit dem Befehl **identify -format "%w"** können wir z.B. die Breite eines Bildes auslesen 

```bash
find . -type f -name "*.jpg" -or -name "*.png" | while read file; do 
# Check if the image needs to be resized
width=$(identify -format "%w" "$file")
height=$(identify -format "%h" "$file")

# check if the watermark need to be resized
width2=$(identify -format "%w" "$watermark")
height2=$(identify -format "%h" "$watermark")

if [[ $width2 -gt $width_watermark ]] || [[ $height2 -gt $height_watermark ]]; then
    # Scale down the watermark to the maximum width and height
    convert "$watermark" -resize "${width_watermark}x${height_watermark}>" "$watermark"
  fi

  if [[ $width -gt $max_width ]] || [[ $height -gt $max_height ]]; then
    # Scale down the image to the maximum width and height
    convert "$file" -resize "${max_width}x${max_height}>" "$file"
  fi

  # Add the watermark to the image
  convert $file Copyright.png -gravity SouthEast -composite $file
 done

```

- Find all images in the var/www/html/wordpress/myimages directory and upload the image to the server in the directory var/www/html/wordpress/myimages
- On the server we also have the directorys var/www/html/wordpress/myimages and in this directories we need to copy the images so that we can upload the on the Webserver

```bash
find var/www/html/wordpress/myimages -type f -name "*.jpg" -or -name "*.png" | while read file; do
  scp "$file" "$username@$hostname:$web_dir"
done
```

- Create HTML file
- we have also linked a CSS file to the HTML file
- The HTML file is formatted like a table

```bash
echo "<!DOCTYPE html>
<html>
<head>
  <title>Gallery</title>
  <link rel='"stylesheet"' type='"text/css"' href='"css/style.css"'/>
  <meta charset='"UTF-8"'>
</head>
<body>
<h1>Website for Images</h1>
<table>
<tr>
  <th>Filename</th>
  <th>Width</th>
  <th>Height</th>
  <th>Date and Time of Download</th>
  <th>Image</th>
</tr>" >gallery.html
```

- Find all images in the var/www/html/wordpress/myimages directory and get the filename and metadata of the image and add a entry for the image to the HTML file
- then write the output into the gallery.html file (without overwriting the file)

```bash

```bash
find var/www/html/wordpress/myimages -type f -name "*.jpg" -or -name "*png" | while read file; do
  # Get the filename and metadata for the image
  filename=$(basename "$file")
  width=$(identify -format "%w px" "$file")
  height=$(identify -format "%h px" "$file")
  date_image=$(stat -c "%.19w" "$file")

  # Add a entry for the image to the HTML file
  echo "<tr>
  <td>$filename</td>
  <td>$width</td>
  <td>$height</td>
  <td>$date_image</td>
  <td><img src="$filename" alt="$filename"></td>
</tr>" >>gallery.html
done
```

- Finish the HTML file

```bash
echo "</table>
</body>
</html>" >>gallery.html
```
## Output
### In the Terminal
- If you use ssh-keys you don't need to enter the password as you can see in the output below

![Terminal](Pictures_Readme/terminal.png)

### In the gallery.html file

- It´s formatted like a table
- And as you can see the pictures are visible on the website

![HTML](Pictures_Readme/Gallery.png)

## bash - commands
**-f** : This option is used with the test command to check if a file is a regular file (not a directory or device file).

**cat** : The cat command is used to concatenate and display the contents of one or more files.

**echo** : This command is used to display a line of text in the terminal.

**">"** : This is a redirection operator in bash, it is used to redirect the output of a command to a file, overwriting the file if it already exists.

**find .** : This command is used to search for files and directories in a directory and subdirectories (in this case, the all directories ".").

**-type** : This option is used with the find command to specify the type of file or directory to search for (e.g. -type f for a regular file, -type d for a directory).

**-name** : This option is used with the find command to specify the name of the file or directory to search for.

**-or** : This option is used to specify multiple conditions in a find command, where only one of the conditions must be met for the file or directory to be returned in the search results.
