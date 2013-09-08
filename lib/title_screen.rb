require 'curses'
module CursesHelper
  def self.extended(base)
    @@cursing = base::CURSING
  end
  def setpos(text, idx)
    Curses.setpos v_center_text(text)+idx-@@cursing.size/2, h_center_text(text)
    Curses.addstr text
  end

  def v_center_text text
    Curses.lines / 2
  end

  def h_center_text text
    (Curses.cols / 2) - (text.length / 2)
  end

  def attrib *attributes
    attributes.each do |attribute|
      Curses.attron  attribute
    end
      yield
    attributes.each do |attribute|
      Curses.attroff  attribute
    end
  end
end

class TitleScreen
  class << self

    CURSING = [ ->(idx) {
      attrib Curses::A_BOLD, Curses::A_UNDERLINE do
        text = "        Columbus Ruby Brigade, The Game          "
        setpos(text, idx)
      end
    }, ->(idx) {
        text = "                     by, Mark J. Lorenz          "
        setpos(text, idx)
    }, ->(idx) {
      attrib Curses::A_UNDERLINE do
        text = "Instructions:                                    "
        setpos(text, idx)
      end
    }, ->(idx) {
        text = " - Use the h, j ,k and l keys to move your ship  "
        setpos(text, idx)
    }, ->(idx) {
        text = " - <space> will insert a \"no move\" unit         "
        setpos(text, idx)
    }, ->(idx) {
        text = " - You get three motion units per game cycle     "
        setpos(text, idx)
    }, ->(idx) {
        text = " - units from last cycle will role over if you   "
        setpos(text, idx)
    }, ->(idx) {
        text = "   don't use all three units this turn. Example: "
        setpos(text, idx)
    }, ->(idx) {
        text = "     if you jkl on turn one and <space>k on      "
        setpos(text, idx)
    }, ->(idx) {
        text = "     turn two, your ship will move l<space>k on  "
        setpos(text, idx)
    }, ->(idx) {
        text = "     turn two.                                   "
        setpos(text, idx)
    }, ->(idx) {
        text = ""
        setpos(text, idx)
    }, ->(idx) {
      attrib Curses::A_UNDERLINE do
        text = "How To Win:                                      "
        setpos(text, idx)
      end
    }, ->(idx) {
        text = " - If a non-vowel [aeiouy] character on your ship"
        setpos(text, idx)
    }, ->(idx) {
        text = "   covers  the vowel of someone else's ship you  "
        setpos(text, idx)
    }, ->(idx) {
        text = "   get one(1) point.                             "
        setpos(text, idx)
    }, ->(idx) {
        text = " - If one of your vowels is covered, you loose   "
        setpos(text, idx)
    }, ->(idx) {
        text = "   one(1) point.                                 "
        setpos(text, idx)
    }, ->(idx) {
      attrib Curses::A_BOLD do
        text = " - Ship with the most points at the end wins!    "
        setpos(text, idx)
      end
    }, ->(idx) {
        text = ""
        setpos(text, idx)
    }, ->(idx) {
      Curses.init_pair(1, Curses::COLOR_WHITE, Curses::COLOR_BLUE)
      attrib Curses::color_pair(1) do
        text = "                          Press <space> to start "
        setpos(text, idx)
      end
    } ]

    extend CursesHelper
    def show
      CURSING.each_with_index do |curse, idx|
        curse.call(idx)
      end
      Curses.refresh
      Curses.getch # Wait for dismissal

      Curses.clear
      Curses.refresh
    end

  end
end

