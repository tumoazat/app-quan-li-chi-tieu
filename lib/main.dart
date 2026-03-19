import 'package:flutter/material.dart';
import 'package:baitap1/widgets/todo_item_widget.dart';

/// Hàm main: điểm vào của ứng dụng
void main() {
  runApp(const MyApp());
}

/// Widget gốc của ứng dụng
/// Cấu hình theme, navigation, và app settings
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      debugShowCheckedModeBanner: false,

      // Cấu hình theme Material 3
      theme: ThemeData(
        useMaterial3: true,
        // Màu chính: purple (#5B4FFF)
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B4FFF),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(elevation: 0, centerTitle: false),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),

      // Trang home: TodoHomePage
      home: const TodoHomePage(),
    );
  }
}

/// Widget trang chủ - hiển thị danh sách todo
/// StatefulWidget vì cần quản lý state (danh sách todo, filter, search)0.
class TodoHomePage extends StatefulWidget {
  const TodoHomePage({super.key});

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

/// Enum định nghĩa 3 loại lọc trạng thái
enum FilterStatus {
  all, // Hiển thị tất cả todo
  pending, // Hiển thị chỉ todo chưa hoàn thành
  completed, // Hiển thị chỉ todo hoàn thành
}

/// State chính của ứng dụng
/// Quản lý:
/// - Danh sách todo (_todos)
/// - Trạng thái lọc (_filterStatus)
/// - Từ khóa tìm kiếm (_searchQuery)
/// - Lịch sử tìm kiếm (_searchHistory)
class _TodoHomePageState extends State<TodoHomePage> {
  // ====== DANH SÁCH DỮ LIỆU ======
  final List<Todo> _todos = []; // Danh sách tất cả todo

  // ====== LỌC VÀ TÌM KIẾM ======
  FilterStatus _filterStatus = FilterStatus.all; // Bộ lọc trạng thái mặc định
  final TextEditingController _inputController =
      TextEditingController(); // TextInput cho thêm/sửa todo
  final TextEditingController _searchController =
      TextEditingController(); // TextInput cho tìm kiếm
  String _searchQuery = ''; // Từ khóa tìm kiếm hiện tại
  final List<String> _searchHistory = []; // Lưu 10 tìm kiếm gần nhất
  bool _showSearchHistory = false; // Có hiển thị lịch sử tìm kiếm hay không

  // ====== DEADLINE VÀ GIỜ ======
  DateTime? _selectedDeadline; // Thời hạn đã chọn (khi thêm/sửa)
  TimeOfDay? _selectedTime; // Giờ đã chọn (khi thêm/sửa)

  @override
  void dispose() {
    // Giải phóng tài nguyên khi widget bị hủy
    _inputController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Thêm tìm kiếm vào lịch sử
  ///
  /// Quy tắc:
  /// - Nếu query đã tồn tại → xóa để thêm lại ở đầu (tránh trùng)
  /// - Giữ tối đa 10 tìm kiếm gần nhất
  /// - Xóa đi tìm kiếm cũ nhất nếu vượt quá 10
  void _addToSearchHistory(String query) {
    if (query.trim().isEmpty) return; // Bỏ qua nếu query rỗng

    setState(() {
      // Xóa nếu đã tồn tại để tránh trùng lặp
      _searchHistory.removeWhere(
        (item) => item.toLowerCase() == query.toLowerCase(),
      );
      // Thêm vào đầu danh sách (tìm kiếm gần nhất)
      _searchHistory.insert(0, query);
      // Giữ chỉ 10 tìm kiếm gần nhất
      if (_searchHistory.length > 10) {
        _searchHistory.removeLast();
      }
    });
  }

  /// Xóa toàn bộ lịch sử tìm kiếm
  /// Hiển thị dialog xác nhận trước khi xóa
  void _clearSearchHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa lịch sử tìm kiếm'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa tất cả lịch sử tìm kiếm?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              setState(() => _searchHistory.clear());
              Navigator.pop(context);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Tìm kiếm từ lịch sử
  ///
  /// Khi người dùng bấm vào một tìm kiếm cũ:
  /// - Đổ dữ liệu tìm kiếm vào search controller
  /// - Cập nhật _searchQuery để lọc danh sách
  /// - Đóng panel lịch sử tìm kiếm
  /// - Thêm vào lịch sử (để lịch sử cập nhật)
  void _searchFromHistory(String query) {
    setState(() {
      _searchController.text = query;
      _searchQuery = query;
      _showSearchHistory = false;
    });
    _addToSearchHistory(query);
  }

  /// Thêm todo mới
  ///
  /// Quy trình:
  /// 1. Kiểm tra title không rỗng (nếu rỗng → hiển thị lỗi)
  /// 2. Tạo Todo object mới với ID = timestamp hiện tại
  /// 3. Thêm vào danh sách _todos
  /// 4. Reset deadline, time
  /// 5. Đóng dialog thêm
  void _addTodo(String title) {
    // Kiểm tra input rỗng
    if (title.trim().isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.error_rounded,
                  color: Colors.red.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Lỗi',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Vui lòng nhập nội dung task!',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Đã hiểu',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
      return; // Dừng thêm nếu không hợp lệ
    }

    // Tạo todo mới và thêm vào danh sách
    setState(() {
      _todos.add(
        Todo(
          id: DateTime.now().toString(), // ID = timestamp hiện tại
          title: title, // Nội dung task
          deadline: _selectedDeadline, // Thời hạn (nếu có)
          time: _selectedTime, // Giờ (nếu có)
        ),
      );
    });

    // Reset deadline, time
    _selectedDeadline = null;
    _selectedTime = null;

    // Đóng dialog thêm
    Navigator.pop(context);
  }

  /// Cập nhật todo hiện có
  ///
  /// Tương tự như _addTodo, nhưng:
  /// - Tìm todo theo id
  /// - Cập nhật title, deadline, time
  void _updateTodo(String id, String newTitle) {
    // Kiểm tra input rỗng
    if (newTitle.trim().isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.error_rounded,
                  color: Colors.red.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Lỗi',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Vui lòng nhập nội dung task!',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Đã hiểu',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // Tìm todo theo id và cập nhật
    setState(() {
      final index = _todos.indexWhere((todo) => todo.id == id);
      if (index != -1) {
        // Cập nhật title, deadline, time
        _todos[index].title = newTitle;
        _todos[index].deadline = _selectedDeadline;
        _todos[index].time = _selectedTime;
      }
    });

    // Reset deadline, time
    _selectedDeadline = null;
    _selectedTime = null;

    // Đóng dialog
    Navigator.pop(context);
  }

  /// Xóa todo
  ///
  /// Hiển thị dialog xác nhận trước khi xóa
  /// Nếu xác nhận → xóa khỏi _todos và hiển thị SnackBar
  void _deleteTodo(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.warning_rounded, color: Colors.red.shade700),
            ),
            const SizedBox(width: 12),
            const Text('Xóa Task'),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn xóa task này? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              // Xóa todo từ danh sách
              setState(() {
                _todos.removeWhere((todo) => todo.id == id);
              });

              // Đóng dialog xác nhận
              Navigator.pop(context);

              // Hiển thị thông báo thành công
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Task đã được xóa thành công'),
                    ],
                  ),
                  backgroundColor: Colors.red.shade600,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  /// Đảo ngược trạng thái hoàn thành của một todo
  ///
  /// Tìm todo theo id, sau đó:
  /// - Nếu isCompleted = false → thay đổi thành true (đã xong)
  /// - Nếu isCompleted = true → thay đổi thành false (chưa xong)
  void _toggleComplete(String id) {
    setState(() {
      final todo = _todos.firstWhere((t) => t.id == id);
      // Đảo ngược trạng thái
      todo.isCompleted = !todo.isCompleted;
    });
  }

  /// Lọc danh sách todo theo 2 điều kiện:
  /// 1. Trạng thái (all / pending / completed)
  /// 2. Từ khóa tìm kiếm (không phân biệt chữ hoa/thường)
  ///
  /// Trả về: Danh sách Todo đã lọc để hiển thị
  List<Todo> _getFilteredTodos() {
    List<Todo> filtered;

    // ===== BƯỚC 1: Lọc theo trạng thái =====
    switch (_filterStatus) {
      case FilterStatus.all:
        // Hiển thị tất cả
        filtered = _todos;
        break;
      case FilterStatus.pending:
        // Chỉ hiển thị chưa hoàn thành (isCompleted = false)
        filtered = _todos.where((todo) => !todo.isCompleted).toList();
        break;
      case FilterStatus.completed:
        // Chỉ hiển thị đã hoàn thành (isCompleted = true)
        filtered = _todos.where((todo) => todo.isCompleted).toList();
        break;
    }

    // ===== BƯỚC 2: Lọc theo từ khóa tìm kiếm =====
    if (_searchQuery.isNotEmpty) {
      // So sánh: todo.title.toLowerCase() contains _searchQuery.toLowerCase()
      // → Không phân biệt chữ hoa/thường
      filtered = filtered.where((todo) {
        return todo.title.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Trả về danh sách đã lọc
    return filtered;
  }

  /// Xóa toàn bộ tìm kiếm
  ///
  /// - Xóa text trong search controller
  /// - Reset _searchQuery về rỗng
  /// - Ẩn panel lịch sử tìm kiếm
  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _showSearchHistory = false;
    });
  }

  /// Xây dựng tiêu đề AppBar
  ///
  /// Nếu không tìm kiếm:
  /// - Hiển thị tiêu đề "Task Manager"
  ///
  /// Nếu đang tìm kiếm:
  /// - Hiển thị search field
  /// - Hiển thị lịch sử tìm kiếm (nếu có)
  Widget _buildAppBarTitle() {
    // Nếu không đang tìm kiếm → hiển thị tiêu đề bình thường
    if (_searchQuery.trim().isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Task Manager',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'Quản lý công việc hiệu quả',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm task...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            border: InputBorder.none,
            prefixIcon: Icon(
              Icons.search,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                Icons.close,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              onPressed: _clearSearch,
            ),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
              _showSearchHistory =
                  value.trim().isEmpty && _searchHistory.isNotEmpty;
            });
          },
          onTap: () {
            setState(() => _showSearchHistory = _searchHistory.isNotEmpty);
          },
          autofocus: true,
        ),
        if (_showSearchHistory && _searchHistory.isNotEmpty)
          Container(
            color: const Color(0xFF7B68EE),
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Lịch sử tìm kiếm',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        GestureDetector(
                          onTap: _clearSearchHistory,
                          child: const Text(
                            'Xóa',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ..._searchHistory.map(
                    (search) => InkWell(
                      onTap: () => _searchFromHistory(search),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.history,
                              size: 16,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                search,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showAddDialog() {
    _inputController.clear();
    _selectedDeadline = null;
    _selectedTime = null;
    showModalBottomSheet(
      context: context,
      builder: (context) =>
          _buildInputDialog(title: 'Thêm Task Mới', onSave: _addTodo),
      isScrollControlled: true,
    );
  }

  void _showEditDialog(Todo todo) {
    _inputController.text = todo.title;
    _selectedDeadline = todo.deadline;
    _selectedTime = todo.time;
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildInputDialog(
        title: 'Sửa Task',
        initialValue: todo.title,
        onSave: (value) => _updateTodo(todo.id, value),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildInputDialog({
    required String title,
    String? initialValue,
    required Function(String) onSave,
  }) {
    if (initialValue != null) {
      _inputController.text = initialValue;
    } else {
      _inputController.clear();
    }

    return StatefulBuilder(
      builder: (context, setState) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                // Input Field
                TextField(
                  controller: _inputController,
                  decoration: InputDecoration(
                    hintText: 'Nhập nội dung task...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(
                      Icons.task_alt,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  maxLines: null,
                  maxLength: 200,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                // Deadline Picker
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Colors.blue.shade600,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hạn chót',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                _selectedDeadline == null
                                    ? 'Chưa chọn'
                                    : '${_selectedDeadline!.day}/${_selectedDeadline!.month}/${_selectedDeadline!.year}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDeadline ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            setState(() => _selectedDeadline = date);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Time Picker
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: Colors.orange.shade600,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Giờ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                _selectedTime == null
                                    ? 'Chưa chọn'
                                    : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _selectedTime ?? TimeOfDay.now(),
                          );
                          if (time != null) {
                            setState(() => _selectedTime = time);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Hủy',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => onSave(_inputController.text),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Lưu',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTodos = _getFilteredTodos();
    final completedCount = _todos.where((t) => t.isCompleted).length;
    final pendingCount = _todos.where((t) => !t.isCompleted).length;
    final totalCount = _todos.length;
    final progressPercent = totalCount == 0
        ? 0.0
        : (completedCount / totalCount);

    // Add search to history when there's a valid search
    if (_searchQuery.trim().isNotEmpty && filteredTodos.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_searchHistory.isEmpty || _searchHistory.first != _searchQuery) {
          _addToSearchHistory(_searchQuery);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF5B4FFF),
        foregroundColor: Colors.white,
        toolbarHeight: 70,
        title: _buildAppBarTitle(),
      ),
      body: CustomScrollView(
        slivers: [
          // Stats Dashboard
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF5B4FFF), const Color(0xFF7B68EE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                children: [
                  // Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tiến độ hôm nay',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${(progressPercent * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progressPercent,
                          minHeight: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.checklist_rtl,
                          label: 'Tổng Task',
                          value: totalCount.toString(),
                          color: Colors.white,
                          bgColor: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.pending_actions,
                          label: 'Chưa Xong',
                          value: pendingCount.toString(),
                          color: Colors.amber.shade200,
                          bgColor: Colors.amber.withValues(alpha: 0.2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.task_alt,
                          label: 'Đã Xong',
                          value: completedCount.toString(),
                          color: Colors.green.shade200,
                          bgColor: Colors.green.withValues(alpha: 0.2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Filter Tabs
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: 'Tất Cả',
                      isActive: _filterStatus == FilterStatus.all,
                      onTap: () =>
                          setState(() => _filterStatus = FilterStatus.all),
                      count: _todos.length,
                    ),
                    const SizedBox(width: 12),
                    _buildFilterChip(
                      label: 'Chưa Xong',
                      isActive: _filterStatus == FilterStatus.pending,
                      onTap: () =>
                          setState(() => _filterStatus = FilterStatus.pending),
                      count: _todos.where((t) => !t.isCompleted).length,
                    ),
                    const SizedBox(width: 12),
                    _buildFilterChip(
                      label: 'Đã Xong',
                      isActive: _filterStatus == FilterStatus.completed,
                      onTap: () => setState(
                        () => _filterStatus = FilterStatus.completed,
                      ),
                      count: _todos.where((t) => t.isCompleted).length,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Todo List
          if (filteredTodos.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        _searchQuery.trim().isNotEmpty
                            ? Icons.search_off
                            : Icons.inbox,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _searchQuery.trim().isNotEmpty
                          ? 'Không tìm thấy kết quả'
                          : 'Không có task nào',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getEmptyMessage(),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: TodoItemWidget(
                    todo: filteredTodos[index],
                    onToggle: () => _toggleComplete(filteredTodos[index].id),
                    onEdit: () => _showEditDialog(filteredTodos[index]),
                    onDelete: () => _deleteTodo(filteredTodos[index].id),
                  ),
                );
              }, childCount: filteredTodos.length),
            ),
          SliverToBoxAdapter(child: const SizedBox(height: 20)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF5B4FFF),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Thêm Task',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  String _getEmptyMessage() {
    if (_searchQuery.trim().isNotEmpty) {
      return 'Thử tìm kiếm với từ khóa khác';
    }

    switch (_filterStatus) {
      case FilterStatus.all:
        return 'Hãy tạo task mới để bắt đầu';
      case FilterStatus.pending:
        return 'Tất cả task đã được hoàn thành!';
      case FilterStatus.completed:
        return 'Bạn chưa hoàn thành task nào';
    }
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required int count,
  }) {
    return Material(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey.shade700,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 6),
              CircleAvatar(
                radius: 10,
                backgroundColor: isActive
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.grey.shade400,
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
