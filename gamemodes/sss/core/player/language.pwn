/*==============================================================================


	Southclaws' Scavenge and Survive

		Copyright (C) 2017 Barnaby "Southclaws" Keene

		This program is free software: you can redistribute it and/or modify it
		under the terms of the GNU General Public License as published by the
		Free Software Foundation, either version 3 of the License, or (at your
		option) any later version.

		This program is distributed in the hope that it will be useful, but
		WITHOUT ANY WARRANTY; without even the implied warranty of
		MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
		See the GNU General Public License for more details.

		You should have received a copy of the GNU General Public License along
		with this program.  If not, see <http://www.gnu.org/licenses/>.


==============================================================================*/



LoadAllLanguages() {
	new
		dir:dirhandle,
		directory_with_root[256],
		item[64],
		type,
		next_path[256],
		default_entries,
		entries,
		languages;

	strcat(directory_with_root, DIRECTORY_LANGUAGES);

	dirhandle = dir_open(directory_with_root);

	if(!dirhandle) {
		err("failed to read directory", _s("directory", directory_with_root));
		return 0;
	}

	// Force load English first since that's the default language.
	default_entries = InitLanguageFromFile(DEFAULT_LANGUAGE, DEFAULT_LANGUAGE);
	log("Default language (English) has %d entries.", default_entries);

	if(default_entries == 0) {
		err("No default entries loaded! Please add the 'English' langfile to '%s'.", directory_with_root);
		return 0;
	}

	while(dir_list(dirhandle, item, type)) {
		if(type == FM_FILE) {
			if(!strcmp(item, DEFAULT_LANGUAGE))
				continue;

			next_path[0] = EOS;
			format(next_path, sizeof(next_path), "%s%s", DIRECTORY_LANGUAGES, item);

			entries = InitLanguageFromFile(next_path, item);

			if(entries > 0) {
				log("successfully loaded language pack",
					_s("item", item),
					_i("entries", entries),
					_i("missing", default_entries - entries));
				languages++;
			} else {
				err("failed to load language pack: no entries loaded",
					_s("item", item));
			}
		}
	}

	dir_close(dirhandle);

	log("Loaded languages", _i("languages", languages));

	return 1;
}

ShowLanguageMenu(playerid) {
	new
		languages[MAX_LANGUAGE][MAX_LANGUAGE_NAME],
		langlist[MAX_LANGUAGE * (MAX_LANGUAGE_NAME + 1)],
		langcount;

	langcount = GetLanguageList(languages);

	for(new i; i < langcount; i++) {
		format(langlist, sizeof(langlist), "%s%s\n", langlist, languages[i]);
	}

	Dialog_Show(playerid, LanguageMenu, DIALOG_STYLE_LIST, "Choose language:", langlist, "Select", "Cancel");
}

Dialog:LanguageMenu(playerid, response, listitem, inputtext[]) {
	if(response) {
		SetPlayerLanguage(playerid, listitem);
		ChatMsgLang(playerid, YELLOW, "LANGCHANGE");
	}
}

hook OnPlayerSave(playerid, filename[]) {
	new data[1];
	data[0] = GetPlayerLanguage(playerid);
	modio_push(filename, _T<L,A,N,G>, 1, data);
}

hook OnPlayerLoad(playerid, filename[]) {
	new data[1];
	modio_read(filename, _T<L,A,N,G>, 1, data);
	SetPlayerLanguage(playerid, data[0]);
}

CMD:language(playerid, params[]) {
	ShowLanguageMenu(playerid);
	return 1;
}
