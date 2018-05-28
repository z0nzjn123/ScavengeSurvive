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


#include <YSI\y_hooks>


hook OnScriptInit() {
	new
		Directory:dir,
		directory_with_root[256] = DIRECTORY_SCRIPTFILES,
		ENTRY_TYPE:type,
		entry[64],
		name[256],
		entries,
		languages;

	strcat(directory_with_root, DIRECTORY_LANGUAGES);

	dir = OpenDir(directory_with_root);
	if(dir == Directory:-1) {
		err("failed to read directory", _s("directory", directory_with_root));
		return 0;
	}

	// Force load English first since that's the default language.
	InitLanguageFromFile(DEFAULT_LANGUAGE);
	log("loaded default language",
		_s("language", DEFAULT_LANGUAGE));

	while(DirNext(dir, type, entry)) {
		if(type == E_REGULAR) {
			if(!strcmp(entry, DEFAULT_LANGUAGE)) {
				continue;
			}

			name[0] = EOS;
			format(name, sizeof(name), "%s%s", DIRECTORY_LANGUAGES, entry);

			InitLanguageFromFile(entry);

			if(entries > 0) {
				log("successfully loaded language pack",
					_s("entry", entry),
					_i("entries", entries));
				languages++;
			} else {
				err("failed to load language pack: no entries loaded",
					_s("entry", entry));
			}
		}
	}

	CloseDir(dir);

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
