-- Create a function to cast to a numeric, if an error occurs return null
create or replace function CAST_TO_NUMERIC(text) returns numeric as $$
begin
    return cast($1 as numeric);
exception
    when invalid_text_representation then
        return null;
end;
$$ language plpgsql immutable;
