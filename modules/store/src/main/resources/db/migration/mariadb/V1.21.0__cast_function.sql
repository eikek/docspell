-- Create a function to cast to a numeric, if an error occurs return null
-- Could not get it working with decimal type, so using double
create or replace function CAST_TO_NUMERIC (s char(255))
returns double deterministic
return cast(s as double);
