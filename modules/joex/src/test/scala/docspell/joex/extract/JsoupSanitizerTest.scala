/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.extract

import java.nio.charset.StandardCharsets

import munit.FunSuite
import org.jsoup.Jsoup

class JsoupSanitizerTest extends FunSuite {

  test("keep interesting tags and attributes") {
    val cleaned = JsoupSanitizer.clean(html)
    val doc = Jsoup.parse(cleaned)

    assertEquals(doc.head().getElementsByTag("link").size(), 1)
    assertEquals(doc.head().getElementsByTag("style").size(), 1)
    assertEquals(doc.charset(), StandardCharsets.UTF_8)
    assertEquals(doc.head().select("meta[charset]").attr("charset").toUpperCase, "UTF-8")
    assert(doc.select("*[class]").size() > 0)
    assert(doc.select("*[style]").size() > 0)
  }

  def html =
    """
      |<!DOCTYPE html>
      |<html lang="en">
      | <head>
      |   <meta charset="utf-8" />
      |   <meta name="viewport" content="width=device-width, initial-scale=1" />
      |   <title>A simple, clean, and responsive HTML invoice template</title>
      |   <link rel="icon" href="./images/favicon.png" type="image/x-icon" />
      |   <style>
      |    body {
      |      font-family: 'Helvetica Neue', 'Helvetica', Helvetica, Arial, sans-serif;
      |    }
      |    body h1 {
      |      font-weight: 300;
      |    }
      |    body h3 {
      |      font-weight: 300;
      |      margin-top: 10px;
      |      color: #555;
      |    }
      |    body a {
      |        color: #06f;
      |    }
      |    .invoice-box {
      |        max-width: 800px;
      |        margin: auto;
      |        padding: 30px;
      |        border: 1px solid #eee;
      |        box-shadow: 0 0 10px rgba(0, 0, 0, 0.15);
      |        font-size: 16px;
      |        line-height: 24px;
      |        font-family: 'Helvetica Neue', 'Helvetica', Helvetica, Arial, sans-serif;
      |        color: #555;
      |    }
      |   </style>
      | </head>
      | <body>
      |   <h1>Some html template for an invoice</h1>
      |   <h3>It is something simple.</h3>
      |   <div class="invoice-box">
      |     <table>
      |       <tr class="top">
      |         <td colspan="2">
      |           <table>
      |             <tr>
      |               <td class="title">
      |                 <img src="./images/logo.png" alt="Company logo" style="width: 100%; max-width: 300px" />
      |               </td>
      |               <td>
      |                 Invoice #: 123<br />
      |                 Created: January 1, 2015<br />
      |                 Due: February 1, 2015
      |               </td>
      |             </tr>
      |           </table>
      |         </td>
      |       </tr>
      |       <tr class="information">
      |         <td colspan="2">
      |           <table style="color: black;">
      |             <tr>
      |               <td>
      |                 Company, Inc.<br />
      |                 456 Rosewood Road<br />
      |                 Flowerville, MI 12345
      |               </td>
      |               <td>
      |                 Acme Corp.<br />
      |                 John Doe<br />
      |                 john@example.com
      |               </td>
      |             </tr>
      |           </table>
      |         </td>
      |       </tr>
      |       <tr class="heading">
      |         <td>Payment Method</td>
      |         <td>Check #</td>
      |       </tr>
      |       <tr class="details">
      |         <td>Check</td>
      |         <td>1000</td>
      |       </tr>
      |       <tr class="heading">
      |         <td>Item</td>
      |         <td>Price</td>
      |       </tr>
      |       <tr class="item">
      |         <td>Website design</td>
      |         <td>$300.00</td>
      |       </tr>
      |       <tr class="item last">
      |         <td>Domain name (1 year)</td>
      |         <td>$10.00</td>
      |       </tr>
      |       <tr class="total">
      |         <td></td>
      |         <td>Total: $385.00</td>
      |       </tr>
      |     </table>
      |   </div>
      | </body>
      |</html>
      |""".stripMargin
}
