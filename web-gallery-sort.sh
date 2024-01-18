#!/bin/bash

# Set the hostname, username, and web directory of the remote server
hostname=eine-firma.de
username=baumgartner
web_dir=/var/www/html/wordpress/myimages
watermark="Copyright.png"

scp -r "css" "$username@$hostname:$web_dir" > output.txt
scp "$watermark" "$username@$hostname:$web_dir" > output.txt

# Get the current date and time
current_time=$(date)

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

# Update the "last_run.txt" file with the current date and time
echo "$current_time" > last_run.txt

# Set the maximum width and height
max_width=320
max_height=200
# Set the maximum width and height for watermark
width_watermark=100
height_watermark=100

# Set the watermark
# watermark="Copyright.png"

# Find all images in the current directory and its subdirectories
find . -type f -name "*.jpg" -or -name "*.png" | while read file; do

# Check if the image needs to be resized
width=$(identify -format "%w" "$file")
height=$(identify -format "%h" "$file")

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

# Create the HTML file
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

# Find all images in the current directory and its subdirectories
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

# Finish the HTML file
echo "</table>
</body>
</html>" >>gallery.html

# Find all images in the  directory 
find var/www/html/wordpress/myimages -type f -name "*.jpg" -or -name "*.png" | while read file; do
  # Upload the image to the remote server
  scp "$file" "$username@$hostname:$web_dir"
  scp "gallery.html" "$username@$hostname:$web_dir" > output.txt
done