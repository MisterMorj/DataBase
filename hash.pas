unit Hash;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;


const
  hash1 = 4477457;
  hash2 = 3229;
  hash3 = 17;


type
  TItemForHash = record
    ID: integer;
    List: TStringList;
  end;

  { THash }

  THash = class (TObject)
    hash_table: array [0..hash1] of TItemForHash;
    function HashVal(Key: integer): integer;
    procedure Add (Item: TItemForHash);
    procedure Remove (Key: integer);
    function ReturnVal (Key: integer): TItemForHash;
  end;

implementation

{ THash }

function THash.HashVal(Key: integer): integer;
begin
  Result := (Key + (Key mod HASH2 + 1) * (Key mod HASH3 + 1)) mod HASH1;
end;

procedure THash.Add(Item: TItemForHash);
var
  p: integer;
  i: integer;
begin
  p := Item.ID mod HASH1;
  while (hash_table[p].ID <> Item.ID) do
  begin
      if (hash_table[p].ID <= 0) then
      begin
        hash_table[p].ID := Item.ID;
        hash_table[p].List := TStringList.Create;
        for i := 0 to Item.List.Count - 1 do
          hash_table[p].List.Add(Item.List[i]);
        break;
      end;
      p := HashVal(p);
  end;
end;

procedure THash.Remove(Key: integer);
var
  p: integer;
begin
  p := Key mod HASH1;
  while (hash_table[p].ID <> Key) do
  begin
    p := HashVal(p);
    if (hash_table[p].ID = 0) then
      break;
  end;
  if (hash_table[p].ID <> 0) then
      hash_table[p].ID := -1;
end;

function THash.ReturnVal(Key: integer): TItemForHash;
var
  p: integer;
begin
  p := Key mod HASH1;
  while (hash_table[p].ID <> Key) do
  begin
      if (hash_table[p].ID <= 0) then
        exit;
      p := HashVal(p);
  end;
  Result := hash_table[p];
end;

end.

