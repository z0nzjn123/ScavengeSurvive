// left-overs from weapon module
// todo: implement into new API and SS storage mechanism

#endinput

hook OnPlayerSave(playerid, filename[]) {
	new
		length,
		data[1 + (MAX_WOUNDS * _:E_WOUND_DATA)];

	length = GetPlayerWoundDataAsArray(playerid, data);

	modio_push(filename, _T<W,N,D,S>, length, data);
}

hook OnPlayerLoad(playerid, filename[]) {
	new data[1 + (MAX_WOUNDS * _:E_WOUND_DATA)];

	modio_read(filename, _T<W,N,D,S>, sizeof(data), data);

	Iter_Clear(wnd_Index[playerid]);
	SetPlayerWoundDataFromArray(playerid, data);
}
