DROP ALIAS IF EXISTS CAST_TO_NUMERIC;
CREATE ALIAS CAST_TO_NUMERIC AS '
import java.text.*;
import java.math.*;
@CODE
BigDecimal castToNumeric(String s) throws Exception {
  try { return new BigDecimal(s); }
  catch (Exception e) {
    return null;
  }
}
'
