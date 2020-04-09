<?php
// 設定
$out_dir=".\\out"; // 出力ディレクトリ

// メインプログラム
echo "DEC_PIGAIMG Ver.02".PHP_EOL.PHP_EOL;
if(isset($_SERVER{'pigaimg_path'})) {
	$in_path=$_SERVER{'pigaimg_path'};
} else {
	echo 'Usage: drag and drop the tape image file to "DEC_PIGAIMG.bat"'.PHP_EOL;
	exit;
}
$in_handle=fopen($in_path, "rb");
$in_head=fread($in_handle,4);
switch($in_head) {
	case 'CTXT':
		$in_filetype="txt";
		$in_mode="cmp";
		echo "Detected as compressed UTF-16LE text".PHP_EOL;
		break;
	case 'RTXT':
		$in_filetype="txt";
		$in_mode="raw";
		echo "Detected as raw UTF-16LE text".PHP_EOL;
		break;
	case 'CGRP':
		$in_filetype="grp";
		$in_mode="cmp";
		echo "Detected as compressed graphic format".PHP_EOL;
		break;
	case 'RGRP':
		$in_filetype="grp";
		$in_mode="raw";
		echo "Detected as BMP format".PHP_EOL;
		break;
	default:
		echo "Error: Unsupported format".PHP_EOL;
		fclose($in_handle);
		exit;
}
fread($in_handle,12);
switch($in_filetype) {
	case 'txt':
		$out_filename_bytes=hexdec(bin2hex(fread($in_handle,1)));
		$out_filename=fread($in_handle,$out_filename_bytes);
		echo "Filename: ".$out_filename.PHP_EOL;
		echo "Decoding...".PHP_EOL;
		$out_path=$out_dir."\\".$out_filename;
		$out_body="";
		for(;;) {
			if(ftell($in_handle)==(filesize($in_path))){
				break;
			}
			$in_data=fread($in_handle,1);
			switch($in_mode) {
				case 'cmp':
					switch(hexdec(bin2hex($in_data))) {
						case 1:
							$out_body.=fread($in_handle,2);
							break;
						default:
							$out_body.=$in_data."\0";
							break;
					}
					break;
				case 'raw':
					$out_body.=$in_data;
					break;
				default:
					echo "Error: Invalid decoding mode".PHP_EOL;
					fclose($in_handle);
					exit;
			}
		}
		file_put_contents($out_path,$out_body);
		echo "Completed".PHP_EOL;
		break;
	case 'grp':
		$out_filename_bytes=hexdec(bin2hex(fread($in_handle,1)));
		$out_filename=fread($in_handle,$out_filename_bytes);
		echo "Filename: ".$out_filename.PHP_EOL;
		echo "Decoding...".PHP_EOL;
		$out_path=$out_dir."\\".$out_filename;
		$out_body="";
		switch($in_mode) {
			case 'cmp':
				$grp_width=fread($in_handle,4);
				$grp_height=fread($in_handle,4);
				$grp_bpp=fread($in_handle,1);
				$grp_width_dec=hexdec(bin2hex(bin_convert_endian($grp_width)));
				$grp_height_dec=hexdec(bin2hex(bin_convert_endian($grp_height)));
				$grp_bpp_dec=hexdec(bin2hex($grp_bpp));
				$grp_rgb888_padding=$grp_width_dec%4;
				switch($grp_bpp_dec) {
					case 32:
						$grp_r_a=grp_decompress($in_handle);
					case 24:
						$grp_r_r=grp_decompress($in_handle);
						$grp_r_g=grp_decompress($in_handle);
						$grp_r_b=grp_decompress($in_handle);
						break;
					default:
						echo "Error: Invalid graphic bpp".PHP_EOL;
						fclose($in_handle);
						exit;
				}
				$out_body=hex2bin('424d'.str_repeat('00',8).'36'.str_repeat('00',3).'28'.str_repeat('00',3)).$grp_width.$grp_height.hex2bin('0100').$grp_bpp.hex2bin(str_repeat('00',25));
				for($p=0;;$p++) {
					if($p==strlen($grp_r_r)) {
						break;
					}
					$out_body.=substr($grp_r_b,$p,1);
					$out_body.=substr($grp_r_g,$p,1);
					$out_body.=substr($grp_r_r,$p,1);
					if ($grp_bpp_dec==32) {
						$out_body.=substr($grp_r_a,$p,1);
					} else if(($p%$grp_width_dec)==($grp_width_dec-1)) {
						$out_body.=str_repeat("\0",$grp_rgb888_padding);
					}
				}
				break;
			case 'raw':
				for(;;) {
					if(ftell($in_handle)==(filesize($in_path))){
						break;
					}
				$out_body.=fread($in_handle,1);
				}
				break;
			default:
				echo "Error: Invalid decoding mode".PHP_EOL;
				fclose($in_handle);
				exit;
		}
		file_put_contents($out_path,$out_body);
		echo "Completed".PHP_EOL;
		break;
	default:
		echo "Error: Decoding function for this format isn't implemented yet".PHP_EOL;
		break;
}
fclose($in_handle);
exit;

function grp_decompress(&$handle) {
	$retval="";
	for(;;) {
		$comp_times=hexdec(bin2hex(fread($handle,1)));
		if($comp_times!=0) {
			$comp_value=fread($handle,1);
			$retval.=str_repeat($comp_value,$comp_times);
		} else {
			break;
		}
	}
	return $retval;
}

function bin_convert_endian($bin_in) {
	$bin_out="";
	for ($c=(strlen($bin_in)-1);$c>=0;$c--) {
		$bin_out.=substr($bin_in,$c,1);
	}
	return $bin_out;
}
