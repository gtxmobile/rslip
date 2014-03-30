class Env < Hash
    def initialize(keys=[],vals=[],outer=nil)
        @outer=outer
        keys.zip(vals).each{|p| store(*p)}
    end
    def [](name) super(name)||@outer[name] end
    def []=(name,val) key?(name) ? store(name,val): @outer[name]=val end
end

def add_globals(env)
    #添加操作符和运算符
    ops=[:+,:-]
    
    env.update({:length => lambda{|x| x.length}})

end

def eval(x,env)
    return env[x] if x.is_a? Symbol
    return x if x.is_a?Array
    case x[0]
        when :if 
            _,test,conseq,alt=x
            eval(eval(test,env) ? conseq:alt,env)
    end
end

def atom(s)
    return "[" if s=='('  
    return "]" if s==')'  
    return s if s =~ /^-?\d+$/ || s =~ /^-?\d*\.\d+$/    #数值转换
    ':'+s   #当为字符串的时候直接输出
    
end

#词法分析
def parse(s)
    toks=s.gsub('(',' ( ').gsub(')',' ) ').split
    Kernel.eval(toks.map{|s| atom(s)}.join(' ').gsub(' ]',']').gsub(/([^\[]) /,'/1, '))
    
end
src =<<CODE  
(begin  
 (define fact (lambda (n)   
  (if (<= n 1) 1 (* n (fact (- n 1))))))  
   
 (fact 5)  
)  
CODE
p src
p parse("(defifa jifa (jfa))")

