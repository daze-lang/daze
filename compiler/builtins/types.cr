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
    @value === other.value
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

  def int
    @value.to_i
  end
end

class DazeInt
  def initialize(@value : Float64)
  end

  def value
    @value
  end

  def int
    @value.to_i
  end

  def +(other : DazeInt)
    @value += other.value
    self
  end

  def -(other : DazeInt)
    @value -= other.value
    self
  end

  def ===(other : DazeInt)
    @value === other.value
    self
  end

  def !=(other : DazeInt)
    @value != other.value
    self
  end

  def >=(other : DazeInt)
    @value >= other.value
    self
  end

  def <=(other : DazeInt)
    @value <= other.value
    self
  end

  def >(other : DazeInt)
    @value > other.value
    self
  end

  def <(other : DazeInt)
    @value < other.value
    self
  end
end

def debug(val)
  pp val
end

def assert(assertion)
  assertion
end
