@tool
extends ConfirmationDialog

const WINDOW_MIN_Y := 143

const TOOL_INFO_TEMPLATE_TEXT := "%s tool haven't been installed on this system yet. Click the button below to install it."
const DOWNLOAD_BTN_TEMPLATE_TEXT := "Download %s tool (2.7MB)"

const ASKALONO_WINDOWS_LINK := "https://github.com/jpeddicord/askalono/releases/download/0.5.0/askalono-Windows.zip"
#const ASKALONO_WINDOWS_ZIPNAME := "askalono.zip"
const ASKALONO_WINDOWS_EXENAME := "askalono.exe" # this must strictly follow what's actually inside the zip

const TOOL_DOWNLOAD_FOLDER_PATH := "user://alicenzia_scan_tools"

@onready var scan_tool_pn_o: HBoxContainer = %ScanToolPnO
@onready var tool_info: Label = %ToolInfo
@onready var download_tool_btn: Button = %DownloadToolBtn
@onready var tool_info_panel: PanelContainer = %ToolInfoPanel

# relative path
@onready var askalono_exe_path := TOOL_DOWNLOAD_FOLDER_PATH + ("/%s" % ASKALONO_WINDOWS_EXENAME) #ASKALONO_WINDOWS_ZIPNAME)


func _ready() -> void:
	self.size.y = WINDOW_MIN_Y
	if not Engine.is_editor_hint():
		_check_if_tool_available()
		_change_tool_texts()

func show_and_update():
	self.show()
	_check_if_tool_available()
	_change_tool_texts()


func _check_if_tool_available():
	var chosen_tool : String = scan_tool_pn_o.get_value()
	match (chosen_tool):
		"askalono":
			var dir = DirAccess.open("user://")
			var okbtn := get_ok_button()
			
			if dir.file_exists(askalono_exe_path):
				_show_tool_download_info(false)
			else:
				_show_tool_download_info(true)
	

func _show_tool_download_info(do_show : bool):
	var okbtn := get_ok_button()
	tool_info_panel.visible = do_show
	#tool_info.visible = do_show
	#download_tool_btn.visible = do_show
	okbtn.disabled = do_show
	if not do_show:
		self.size.y = WINDOW_MIN_Y


func _change_tool_texts():
	var chosen_tool : String = scan_tool_pn_o.get_value()
	tool_info.text = TOOL_INFO_TEMPLATE_TEXT % chosen_tool
	download_tool_btn.text = DOWNLOAD_BTN_TEMPLATE_TEXT % chosen_tool


func _on_scan_tool_pn_o_selected_item_changed(item_name: String) -> void:
	_change_tool_texts()


func _on_download_tool_btn_pressed() -> void:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_tool_download_completed)
	
	download_tool_btn.disabled = true
	scan_tool_pn_o.disable_option_btn(true)
	
	print("Downloading file...")
	var error = http_request.request(ASKALONO_WINDOWS_LINK)
	if error != OK:
		push_error("An error occurred in the HTTP request.")


func _tool_download_completed(result, response_code, headers, body):
	download_tool_btn.disabled = false
	scan_tool_pn_o.disable_option_btn(false)
	
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("Tool couldn't be downloaded. Retry, check your internet connection, or report this as a bug.")
	else:
		## save the downloaded zip
		var dir = DirAccess.open("user://")
		dir.make_dir_recursive(TOOL_DOWNLOAD_FOLDER_PATH)
		var zip_name := ASKALONO_WINDOWS_LINK.get_slice("/", ASKALONO_WINDOWS_LINK.split("/").size() - 1) # get zip name from link
		var zip_download_path := TOOL_DOWNLOAD_FOLDER_PATH + ("/%s" % zip_name) #ASKALONO_WINDOWS_ZIPNAME)
		#print(zip_download_path)
		var zip_file = FileAccess.open(zip_download_path, FileAccess.WRITE)
		zip_file.store_buffer(body) # write downloaded file byte to physical file on local storage
		zip_file.close()
		
		## extract the executable from zip and save it
		var reader = ZIPReader.new()
		var err = reader.open(zip_download_path)
		if err != OK:
			print("this errors out: %d" % err)
			return PackedByteArray()
		var askalono_tool := reader.read_file(ASKALONO_WINDOWS_EXENAME)
		var exe_file = FileAccess.open(askalono_exe_path, FileAccess.WRITE)
		exe_file.store_buffer(askalono_tool)
		reader.close()
		exe_file.close()
		
		print("File downloaded!")
		
		_show_tool_download_info(false)


func begin_scan() -> Array[Dictionary]:
	var askalono_exe_globalpath := ProjectSettings.globalize_path(askalono_exe_path)
	var addon_folder_globalpath := ProjectSettings.globalize_path("res://addons")
	#var addon_folder_gpath_split_size := addon_folder_globalpath.split("/", false).size()
	var output = []
	var exit_code = OS.execute(askalono_exe_globalpath, ["--format", "json", "crawl", addon_folder_globalpath], output)
	if not output[0]:
		push_error("No output found")
		return Array()
	
	var path_license_dict_array : Array[Dictionary]
	
	for spotted_license_json in output[0].split("\n", false):
		var spotted_license_dict = JSON.parse_string(spotted_license_json)
		var license_path : String = spotted_license_dict["path"]
		var license_path_relative := license_path.trim_prefix(addon_folder_globalpath)
		if license_path_relative.split("\\", false).size() > 2:
			continue # skip license file found deep inside an addon, for now

		var result_dict : Dictionary = spotted_license_dict["result"]
		var license_dict : Dictionary = result_dict["license"]
		var license_name : String = license_dict["name"]
		var copyright_year : int
		var copyright_owner : String
		
		if license_name in ["MIT"]: # supported license type to search with regex
			var full_license_text := FileAccess.get_file_as_string(license_path)
			var regex = RegEx.new()
			const year_owner_search_pattern := r"Copyright\s+(?:\([cC]\)\s+|©\s+)?(?:(\d{4}(?:-\d{4})?)\s+)?(.*)" # Gemini 3.1 Pro provided this
			regex.compile(year_owner_search_pattern) 
			var result = regex.search(full_license_text)
			if result:
				copyright_year = int(result.get_string(1))
				copyright_owner = result.get_string(2)

		var path_license_dict := Dictionary() # NEED A BETTER TERM
		path_license_dict["name"] = license_path_relative.get_slice("\\", 1) # for example, \alicenzia\LICENSE got alicenzia
		path_license_dict["license"] = license_name
		path_license_dict["copyright_year"] = copyright_year
		path_license_dict["copyright_owner"] = copyright_owner
		path_license_dict_array.append(path_license_dict)
		print(	"path: %s | license : %s | year : %d | owner : %s"
				% [license_path_relative, license_name, copyright_year, copyright_owner])
	
	print("scan done!")
	return path_license_dict_array
