package docspell.files

case class Dimension(width: Int, height: Int) {

  def toAwtDimension: java.awt.Dimension =
    new java.awt.Dimension(width, height)
}
