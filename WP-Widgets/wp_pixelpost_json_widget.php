<?php
/*
Plugin Name: WP-PixelpostJSONWidget
Plugin URI: http://blog.knut.me/
Description: This widget fetches the json output from a pixelpost photoblog and displays the last pictures in the sidebar. Requires <a href="http://www.pixelpost.org/extend/addons/json-output-for-pixelpost/" target="_blank">JSON Output for Pixelpost</a> to be installed in the photoblog.
Version: 0.3
Author: Knut Ahlers
Author URI: http://blog.knut.me/
*/
/*  Copyright 2009  Knut Ahlers  (email: knut@ahlers.me)

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

function WPPixelpostJSONGenerate($src, $number) {
	
	// Build the URL and get the contents of the JSON
	$url = $options['src'] . "/index.php?z=json&number=" . $options['number'];
	$src = file_get_contents($url);

	// Quick-n-Dirty cleanup of the javascript trash in the plugin output...
	$src = str_replace('jsonPixelpostFeed(', '', $src);
	$src = str_replace('})', '}', $src);
	// I'm sorry for this but the author thought only about javascript so I
	// have to do the cleanup here. If you want to kick someone for this please
	// kick the author of the pixelpost plugin.

	// Extract the contents from the JSON
	$json = json_decode($src);
	
	// Set the title to the photoblog-stream
	$title = $json->{'title'};
	
	$html = "";
	
	// Print out every image vertically
	foreach($json->{'items'} as $item) {
		$html .= "<a href=\"" . $item->{'link'} . "\">";
		$html .= "<img src=\"" . $item->{'thumbnail'} . "\" alt=\"" . $item->{'title'} . "\" style=\"border:0;\" />";
		$html .= "</a><br />";
	}
	
	return array('html' => $html, 'title' => $title);
}

function WPPixelpostJSONOutput($src, $number) {
	
	// Get the code for the html content
	$res = WPPixelpostJSONGenerate($src, $number);
	
	// Print out the images
	echo $res['html'];
}

function WPPixelpostJSONWidgetINIT() {
	
	// If there is no sidebar-widget-functionality skip everything. Then the
	// plugin will not work. Sorry.
	if ( !function_exists('register_sidebar_widget') || !function_exists('register_widget_control') )
            return;

	// The stuff for the admin panel
	function WPPixelpostJSONWidget_control() {
		$options = $newoptions = get_option('WPPixelpostJSONWidget');
		
		// If there are new options set read them from the browser
		if($_POST['WPPixelpostJSONWidget_submit']) {
			$newoptions['src'] = strip_tags(stripslashes($_POST['WPPixelpostJSONWidget-src']));
			$newoptions['number'] = strip_tags(stripslashes($_POST['WPPixelpostJSONWidget-number']));
		}
		
		// If the options changed write them to the wordpress database
		if ( $options != $newoptions ) {
                $options = $newoptions;
                update_option('WPPixelpostJSONWidget', $options);
        }

		// Default value for the number of pictures
		if ($options['number'] == '')
			$options['number'] = '3';
		
		// Some HTML-Stuff for the administration panel.	
		?>
<p style="text-align:left"><label for="WPPixelpostJSONWidget-src">Basisurl (Ohne letztes "/"): <br/><input style="width: 250px;" id="WPPixelpostJSONWidget-src" name="WPPixelpostJSONWidget-src" value="<?php echo wp_specialchars($options['src'], true); ?>" type="text"></label></p>
<p style="text-align:left"><label for="WPPixelpostJSONWidget-number">Anzahl Bilder: <br/><input style="width: 250px;" id="WPPixelpostJSONWidget-number" name="WPPixelpostJSONWidget-number" value="<?php echo wp_specialchars($options['number'], true); ?>" type="text"></label></p>
<input type="hidden" name="WPPixelpostJSONWidget_submit" id="delicious-submit" value="1" />
		<?
	}

	// The stuff to print everything into your frontend.
	function WPPixelpostJSONWidget($args) {
		
		extract($args);
		
		// Get the options from the database
		$options = (array) get_option('WPPixelpostJSONWidget');
		
		// Get the code for the widget content
		$res = WPPixelpostJSONGenerate($options['src'], $options['number']);
		
		// Set the title to the photoblog-stream
		$title = $res['title'];
		
		// Print the defined startup for the widget
		echo $before_widget . $before_title . $title . $after_title;
		echo "<p style=\"text-align:center;margin-bottom:0px;padding:4px;\">";
		
		// Print out the images
		echo $res['html'];
		
		// Finish the widget
		echo "</p>";
		echo $after_widget;
	}
	
	// Tell Wordpress what to do at every stage for this widget.
	register_sidebar_widget('WP-PixelpostJSONWidget', 'WPPixelpostJSONWidget');
	register_widget_control('WP-PixelpostJSONWidget', 'WPPixelpostJSONWidget_control',300,300);

}

add_action('plugins_loaded', 'WPPixelpostJSONWidgetINIT');

?>