import 'package:flutter/material.dart';

/// Model class đại diện cho một Task/Công việc
///
/// Chứa tất cả thông tin cần thiết của một task:
/// - id: ID duy nhất (dùng để xác định task)
/// - title: Nội dung của task
/// - isCompleted: Trạng thái hoàn thành (true = đã xong, false = chưa xong)
/// - createdAt: Thời gian tạo task
/// - deadline: Thời hạn hoàn thành (tùy chọn, có thể null)
/// - time: Giờ cụ thể để làm task (tùy chọn, có thể null)
class Todo {
  String id; // ID duy nhất của task
  String title; // Nội dung task
  bool isCompleted; // Trạng thái (hoàn thành/chưa hoàn thành)
  DateTime createdAt; // Ngày giờ tạo task
  DateTime? deadline; // Thời hạn (optional - có thể null)
  TimeOfDay? time; // Giờ cụ thể (optional - có thể null)

  /// Constructor tạo mới một Todo
  /// [id] và [title] bắt buộc phải cung cấp
  /// [createdAt] mặc định là thời gian hiện tại nếu không truyền
  Todo({
    required this.id,
    required this.title,
    this.isCompleted = false,
    DateTime? createdAt,
    this.deadline,
    this.time,
  }) : createdAt = createdAt ?? DateTime.now();
}

/// Widget hiển thị một item Todo (công việc) trong danh sách
///
/// Đây là một StatefulWidget vì nó cần quản lý animation khi người dùng click
/// Widget nhận vào:
/// - [todo]: Đối tượng Todo cần hiển thị
/// - [onToggle]: Callback khi người dùng bấm checkbox (đánh dấu hoàn thành)
/// - [onEdit]: Callback khi người dùng bấm nút sửa
/// - [onDelete]: Callback khi người dùng bấm nút xóa
class TodoItemWidget extends StatefulWidget {
  final Todo todo; // Dữ liệu task cần hiển thị
  final VoidCallback onToggle; // Sự kiện: đánh dấu hoàn thành
  final VoidCallback onEdit; // Sự kiện: chỉnh sửa
  final VoidCallback onDelete; // Sự kiện: xóa

  const TodoItemWidget({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<TodoItemWidget> createState() => _TodoItemWidgetState();
}

/// State của TodoItemWidget
/// Quản lý animation khi người dùng click vào todo item
class _TodoItemWidgetState extends State<TodoItemWidget>
    with SingleTickerProviderStateMixin {
  // Animation controller: điều khiển hiệu ứng scale (phóng to/thu nhỏ)
  late AnimationController _animationController;

  // Animation: thu nhỏ item khi bấm (1.0 → 0.98) rồi phóng to lại
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Khởi tạo animation controller
    // Duration: 300ms là thời gian animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Tạo animation: thay đổi scale từ 1.0 → 0.98
    // Sử dụng EaseInOut curve để animation mượt hơn
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    // Giải phóng animation controller khi widget bị hủy
    _animationController.dispose();
    super.dispose();
  }

  /// Hàm build: xây dựng giao diện của todo item
  ///
  /// Cấu trúc:
  /// - GestureDetector: Phát hiện khi người dùng bấm
  /// - ScaleTransition: Áp dụng animation scale
  /// - Card: Container chính
  /// - Row: Chứa checkbox, tiêu đề, nút sửa/xóa
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // onTapDown: Khi người dùng bấm xuống → animation forward (thu nhỏ)
      onTapDown: (_) => _animationController.forward(),
      // onTapUp: Khi người dùng nhả tay → animation reverse (phóng to)
      onTapUp: (_) => _animationController.reverse(),
      // onTapCancel: Nếu bấm nhưng kéo ra ngoài → animation reverse
      onTapCancel: () => _animationController.reverse(),

      // ScaleTransition: Áp dụng animation scale cho toàn bộ todo item
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          shadowColor: Colors.grey.withValues(alpha: 0.2),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.todo.isCompleted
                    ? Colors.green.shade200
                    : Colors.grey.shade200,
                width: 1.5,
              ),
              color: widget.todo.isCompleted
                  ? Colors.green.shade50
                  : Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Custom Checkbox with Animation
                  GestureDetector(
                    onTap: widget.onToggle,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.todo.isCompleted
                              ? Colors.green
                              : Colors.grey.shade400,
                          width: 2.5,
                        ),
                        color: widget.todo.isCompleted
                            ? Colors.green
                            : Colors.transparent,
                      ),
                      child: widget.todo.isCompleted
                          ? const Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Todo Title & Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.todo.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: widget.todo.isCompleted
                                ? Colors.grey.shade500
                                : Colors.grey.shade900,
                            decoration: widget.todo.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            decorationColor: Colors.grey.shade500,
                            decorationThickness: 2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatDate(widget.todo.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        // Deadline info
                        if (widget.todo.deadline != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 13,
                                color: _getDeadlineColor(),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDeadline(widget.todo.deadline!),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _getDeadlineColor(),
                                ),
                              ),
                              if (widget.todo.time != null) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.access_time,
                                  size: 13,
                                  color: Colors.orange.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.todo.time!.hour.toString().padLeft(2, '0')}:${widget.todo.time!.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange.shade600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Action Buttons
                  _buildActionButton(
                    icon: Icons.edit_rounded,
                    color: Colors.blue,
                    onTap: widget.onEdit,
                  ),
                  const SizedBox(width: 4),
                  _buildActionButton(
                    icon: Icons.delete_outline_rounded,
                    color: Colors.red,
                    onTap: widget.onDelete,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final todayDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (todayDate == today) {
      return 'Hôm nay • ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (todayDate == yesterday) {
      return 'Hôm qua';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final deadlineDate = DateTime(deadline.year, deadline.month, deadline.day);

    if (deadlineDate == today) {
      return 'Hôm nay';
    } else if (deadlineDate == tomorrow) {
      return 'Ngày mai';
    } else if (deadlineDate.isBefore(today)) {
      return 'Quá hạn';
    } else {
      final daysLeft = deadlineDate.difference(today).inDays;
      return 'Còn $daysLeft ngày';
    }
  }

  Color _getDeadlineColor() {
    if (widget.todo.deadline == null) return Colors.grey.shade600;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDate = DateTime(
      widget.todo.deadline!.year,
      widget.todo.deadline!.month,
      widget.todo.deadline!.day,
    );

    if (deadlineDate.isBefore(today)) {
      return Colors.red.shade600; // Quá hạn
    } else if (deadlineDate == today) {
      return Colors.orange.shade600; // Hôm nay
    } else if (deadlineDate.difference(today).inDays <= 2) {
      return Colors.amber.shade600; // Sắp tới
    } else {
      return Colors.blue.shade600; // Còn thời gian
    }
  }
}
