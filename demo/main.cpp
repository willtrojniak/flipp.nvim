#include <iostream>
#include <vector>

namespace NVIM {
class Flipp {
public:
  Flipp();
  ~Flipp();
  Flipp(const Flipp &) = delete;

  std::vector<int> scores() const;
  virtual void update() = 0;
  static char **names();
};
} // namespace NVIM

int main() {
  std::cout << "Hello Flipp!" << std::endl;

  return 0;
}
