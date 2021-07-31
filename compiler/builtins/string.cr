class DazeString
  def initialize(@value : String)
  end

  def split(delim : DazeString)
    @value.split(delim.value)
  end

  def reverse
    @value.reverse
  end

  def [](index : Int)
    @value[index]
  end

  def +(other : DazeString)
    @value + other.value
  end

  def value
    @value
  end

  def len
    @value.length
  end
end

module DazeModule
  def len(val : Any)
    val.length
  end
end
