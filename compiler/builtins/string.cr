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

  def ===(other : DazeString)
    return @value === other.value
  end

  def value
    @value
  end

  def includes(char : DazeString)
    @value.includes? char.value
  end

  def len
    @value.length
  end
end
